import '../../l10n/l10n.dart';

/// Which pose the mascot takes. Each screen picks the one that matches its mood.
enum Scene { home, alert, guide, map }

class SceneInfo {
  const SceneInfo({required this.eyebrow, required this.title, required this.sub, required this.mood});

  final String eyebrow;
  final String title;
  final String sub;
  final String mood;
}

SceneInfo sceneInfo(AppLocalizations l, Scene scene) => switch (scene) {
      Scene.home => SceneInfo(eyebrow: l.sceneHomeEyebrow, title: '', sub: l.sceneHomeSub, mood: l.moodWelcome),
      Scene.alert => SceneInfo(eyebrow: '', title: '', sub: '', mood: l.moodFocused),
      Scene.guide => SceneInfo(
          eyebrow: l.sceneGuideEyebrow, title: l.sceneGuideTitle, sub: l.sceneGuideSub, mood: l.moodHelpful),
      Scene.map =>
        SceneInfo(eyebrow: l.sceneMapEyebrow, title: l.sceneMapTitle, sub: l.sceneMapSub, mood: l.moodDetermined),
    };
