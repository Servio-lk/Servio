class EmailValidator {
  EmailValidator._();

  static final RegExp _emailPattern = RegExp(
    r"^[a-z0-9.!#$%&'*+/=?^_`{|}~-]+@"
    r"[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?"
    r"(?:\.[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?)+$",
    caseSensitive: false,
  );

  static const Set<String> _commonGenericTlds = {
    'com',
    'org',
    'net',
    'edu',
    'gov',
    'mil',
    'info',
    'biz',
    'name',
    'dev',
    'app',
    'io',
    'ai',
    'co',
    'me',
    'tv',
    'xyz',
    'pro',
    'tech',
    'cloud',
    'store',
    'shop',
    'online',
    'site',
    'blog',
    'live',
    'news',
    'media',
    'club',
    'digital',
    'solutions',
    'services',
    'agency',
    'company',
    'group',
    'finance',
    'travel',
  };

  static bool isValid(String value) {
    final email = value.trim().toLowerCase();
    if (email.isEmpty || !_emailPattern.hasMatch(email)) {
      return false;
    }

    final parts = email.split('@');
    if (parts.length != 2) return false;

    final domainParts = parts[1].split('.');
    if (domainParts.length < 2) return false;

    final tld = domainParts.last;
    if (tld.length == 2) return true; // country-code TLDs, e.g. .lk, .uk
    return _commonGenericTlds.contains(tld);
  }
}
