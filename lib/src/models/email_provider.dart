/// Supported email providers for the Huefy API.
enum EmailProvider {
  ses('ses'),
  sendgrid('sendgrid'),
  mailgun('mailgun'),
  mailchimp('mailchimp');

  /// The string value sent to the API.
  final String value;

  const EmailProvider(this.value);

  /// Returns the [EmailProvider] for the given [value], or `null` if not found.
  static EmailProvider? fromValue(String value) {
    for (final provider in EmailProvider.values) {
      if (provider.value == value) {
        return provider;
      }
    }
    return null;
  }

  @override
  String toString() => value;
}
