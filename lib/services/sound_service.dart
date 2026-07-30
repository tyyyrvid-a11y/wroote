import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Os sons da interface. Cada um tem um volume relativo próprio porque os
/// arquivos não foram normalizados entre si: `hover` dispara dezenas de
/// vezes por minuto e precisa ficar no limite do subliminar, enquanto
/// `success` é um evento raro que pode se dar ao luxo de ser ouvido.
enum UiSound {
  /// Clique em botão, item de lista, aba.
  tap('tap.wav', 0.35),

  /// Cursor entrando em algo clicável. Bem baixo, e com _throttle_.
  hover('hover.wav', 0.12),

  /// Abrir livro, diálogo, painel.
  open('open.wav', 0.5),

  /// Fechar diálogo, voltar para a biblioteca.
  close('close.wav', 0.45),

  /// Trocar de página/capítulo no editor.
  page('page.wav', 0.4),

  /// Alternar tema, expandir/recolher, marcar opção.
  toggle('toggle.wav', 0.4),

  /// Criar livro/capítulo/página, salvar concluído.
  success('success.wav', 0.5),

  /// Confirmação de exclusão.
  delete('delete.wav', 0.5),

  /// Ação recusada (ex.: apagar o último capítulo).
  blocked('blocked.wav', 0.5);

  const UiSound(this.asset, this.gain);

  /// Caminho dentro de `assets/` — o [AssetSource] já assume esse prefixo.
  final String asset;

  /// Volume relativo do som, multiplicado pelo volume global.
  final double gain;

  AssetSource get source => AssetSource('sounds/$asset');
}

/// Toca os efeitos sonoros da interface.
///
/// Mantém um punhado de [AudioPlayer]s em rodízio: um único player cortaria
/// o som anterior a cada novo disparo, e criar um player por clique gera
/// alocação (e latência) demais para algo que acontece a cada interação.
class SoundService extends ChangeNotifier {
  static const _prefsEnabledKey = 'sound_enabled';
  static const _prefsVolumeKey = 'sound_volume';

  /// Quantos sons podem soar simultaneamente antes de começar a cortar o
  /// mais antigo. Quatro cobre o pior caso real (hover + clique + som da
  /// ação resultante) com folga.
  static const _poolSize = 4;

  /// Intervalo mínimo entre dois sons de hover. Sem isso, arrastar o mouse
  /// por uma lista vira uma metralhadora.
  static const _hoverThrottle = Duration(milliseconds: 70);

  final List<AudioPlayer> _pool = [];
  int _next = 0;
  bool _initialized = false;

  bool _enabled = true;
  double _volume = 0.7;
  DateTime _lastHover = DateTime.fromMillisecondsSinceEpoch(0);

  bool get enabled => _enabled;
  double get volume => _volume;

  /// Carrega as preferências e prepara os players. Falhas aqui (áudio
  /// indisponível, driver ausente) apenas desligam o som — nunca derrubam
  /// o app, porque som é enfeite, não funcionalidade.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      _enabled = prefs.getBool(_prefsEnabledKey) ?? true;
      _volume = prefs.getDouble(_prefsVolumeKey) ?? 0.7;
    } catch (error) {
      debugPrint('SoundService: não foi possível ler as preferências ($error)');
    }

    try {
      for (var i = 0; i < _poolSize; i++) {
        final player = AudioPlayer(playerId: 'wroote_ui_$i');
        // `stop` (em vez de `release`) mantém o arquivo decodificado entre
        // execuções, que é o que torna o segundo clique tão rápido quanto
        // o primeiro.
        await player.setReleaseMode(ReleaseMode.stop);
        await player.setPlayerMode(PlayerMode.lowLatency);
        _pool.add(player);
      }
    } catch (error) {
      debugPrint('SoundService: áudio indisponível, som desligado ($error)');
      _pool.clear();
      _enabled = false;
    }

    notifyListeners();
  }

  Future<void> setEnabled(bool value) async {
    if (_enabled == value) return;
    _enabled = value;
    notifyListeners();
    // Confirma a ativação com um som audível: sem isso o usuário liga o
    // som e não tem nenhuma prova de que funcionou.
    if (value) play(UiSound.toggle);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsEnabledKey, value);
    } catch (error) {
      debugPrint('SoundService: não foi possível salvar o estado ($error)');
    }
  }

  Future<void> setVolume(double value) async {
    final clamped = value.clamp(0.0, 1.0);
    if (_volume == clamped) return;
    _volume = clamped;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_prefsVolumeKey, clamped);
    } catch (error) {
      debugPrint('SoundService: não foi possível salvar o volume ($error)');
    }
  }

  /// Dispara [sound]. Deliberadamente sem `await`: quem chama está no meio
  /// de um `onTap` e não deve esperar o áudio para seguir com a ação.
  void play(UiSound sound) {
    if (!_enabled || _pool.isEmpty) return;

    if (sound == UiSound.hover) {
      final now = DateTime.now();
      if (now.difference(_lastHover) < _hoverThrottle) return;
      _lastHover = now;
    }

    final player = _pool[_next];
    _next = (_next + 1) % _pool.length;

    unawaited(_play(player, sound));
  }

  Future<void> _play(AudioPlayer player, UiSound sound) async {
    try {
      await player.stop();
      await player.setVolume((_volume * sound.gain).clamp(0.0, 1.0));
      await player.play(sound.source);
    } catch (error) {
      debugPrint('SoundService: falha ao tocar ${sound.asset} ($error)');
    }
  }

  @override
  void dispose() {
    for (final player in _pool) {
      player.dispose();
    }
    _pool.clear();
    super.dispose();
  }
}

/// Açúcar para `context.read<SoundService>()`, que aparece em praticamente
/// todo widget interativo do app.
///
/// Usa `Provider.of` em vez do atalho `read` porque chamar a extensão de um
/// pacote de dentro de outra extensão depende de regras de resolução
/// sutis; a forma estática não deixa margem a dúvida. `listen: false` é o
/// essencial aqui: tocar um som nunca deve reconstruir quem o toca.
extension SoundServiceX on BuildContext {
  SoundService get sounds => Provider.of<SoundService>(this, listen: false);
}
