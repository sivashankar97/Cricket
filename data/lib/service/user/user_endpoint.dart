import '../../api/network/endpoint.dart';

/// Formerly called Cloud Function `POST /user/create` (arbitrary Auth user
/// creation). That endpoint is disabled (410). Kept only so old imports
/// compile; do not use.
@Deprecated('Cloud Function /user/create is removed')
class CreateUserEndpoint extends Endpoint {
  final String phone;
  final String name;

  CreateUserEndpoint({
    required this.phone,
    required this.name,
  });

  @override
  String get path => 'user/create';

  @override
  HttpMethod get method => HttpMethod.post;

  @override
  dynamic get data => {"phone": phone, "name": name};
}
