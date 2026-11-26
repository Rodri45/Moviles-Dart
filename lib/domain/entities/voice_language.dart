enum VoiceLanguage {
  spanish('es-CO', 'Español'),
  english('en-US', 'English');

  const VoiceLanguage(this.localeId, this.label);

  final String localeId;
  final String label;
}
