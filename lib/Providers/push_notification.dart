// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:googleapis_auth/auth_io.dart';

class PushNotificationFunction {
  // for sending push notification
  static Future<void> sendPushNotification(
      String title, String msg, String token) async {
    var jsonCredentials = r'''
{
  "type": "service_account",
  "project_id": "thuma-mina-9d738",
  "private_key_id": "c05dd769625d325f92abd112c07a181ad325fed5",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQC5XZItqVyPf2TB\npLYvYnRuEAeDc3JnObjlDdEM0jX0+wnWa40zn8AGoeCluge3s3QhW78PGE279SV8\nCXAguUiFvBpq8OdHo0LCSsBTm/vTxN72xFGI5zbbfW4ehalDpoNnF+W1x9SlItQG\nc5ujaXbDBTdiwj9t48PmFSf7CBPj5ND3ToNY0DgOVBUzxVU6zNZKeOAwqBkZd6aO\nWyQ7e+51mUdWUQ9a919oixSEgIFF9Dk+MiqZBeZTDEqwQ1BmDsWbHCdwkYJxNGRw\nX9aAT21U3x4KGszPzxRE6mQXASP93KN4+I3EkgI0rjvnm3eeH9JhWYtPecKP/tf4\nqJEZjI61AgMBAAECggEACUnLmu9MhKHoS/4OJU/cZYMhm+qzbeyPRnumVkC2n0Tb\nVcEeupppDkawbErRpgOUuzLZnxluFGVAtddTj5w2gAGwhtvKka/NVvwqaMtyjLEQ\ner0pwxT843YvR/xqwnRL9iTqfSzwdj7exhz8Ye2VW8koNjy6s22xNwH9NnUNlBgg\n9TSKqsoQPOTpzF4DxcA0zJZkCyeuZpxyTy88DcTvT1g+FWthnFPVCqToLCA6SNte\nU455WMG44KfhZBNNRceeUdR29Aq5wrD54cnzmmLbaEsbSpzSRtd+EPeVL34azio2\nrIA56PsFfhQ+o70vU/zyso3nkdxwEN9PA4+w6Zrb+QKBgQDsy1jfhtsHdjG2qqGN\nxI39urL8jHGa5nH/EGQ1rX85nbfw+SF/nRrPPnIQ7GsewBVSzO4flKc1sljBfdTw\nIDEBzi1cZfOgyqkNRuQzGULcU1+FPYZ0qpXTPfX5tk2i0PJbbuWyRsv6viBxkycB\nWf2Xb12Q/u7HCjmwCzCvyZ46TQKBgQDIZmMqJP0Uqdgqm7vYyU1tH0z07LAI1xd8\ngJRET+V02jOqBhlZKAkCEpJ1E1UxK55Z/4ScYu5nXzR1QBJFMKAWcAUZTvhMqgpU\nwdqVcQ53aWLjut5El3+rDNDXxQo+/VJdZT6AAdX5Iyy86pKCOAdwIV3tCpwMKVFm\nj+l2r0uKCQKBgH/GarqTZnVsTf8nq+139rbHm/WzQ0o2t6TPD4P3jwNkG/GoPW9D\nM0hJhfuj11nMhLUdaBEage/zwPkIEXNRq6AxxUBqs0A8m2RSsKjyJKYHRy/6tycV\nNau7b5PDz7jfzyePe9rrYP54wcEHirCsAq9IpNCs/+PfnKlmIGt6/CqxAoGBAIPN\nC0VppGXVuw1y9Z4D739oibXAgZqe1JyW+GzhW1l6NWaKsls4AIyzaE3F1E8NkA1D\nB5XPX1rve9HtvNZyv6diL4hQru/FGhxajwegntIcpuR+P7c/KMF4IVb4CeAZvfUd\nJHkOPAuqfb8WTBuG/CVcXKkNREqfViEtX3AmpHj5AoGBAJFLj8eNFQQaB1SfySEn\nvjKChFXFwuqxp3x2oWVSTnhYEaFMpAFK7LvNPha9qHL8ugfuUvugu3AK94ojTwe/\nJrJ/SDyI4PfgIa6LYhV3eWzVV9rxnCpQvwET9RAcEYN2dKzq36NkaJX+CZ22k0Tl\nzYDPqoTOHHK5cmRyV/KO/8ia\n-----END PRIVATE KEY-----\n",
  "client_email": "thuma-mina-9d738@appspot.gserviceaccount.com",
  "client_id": "115651733722277042925",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/thuma-mina-9d738%40appspot.gserviceaccount.com",
  "universe_domain": "googleapis.com"
}
 ''';

    var credentials = ServiceAccountCredentials.fromJson(jsonCredentials);

    // Scopes for Firebase Cloud Messaging
    const scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

    // Authenticate and obtain an HTTP client
    var client = await clientViaServiceAccount(credentials, scopes);

    // FCM endpoint for HTTP v1 requests
    String url =
        'https://fcm.googleapis.com/v1/projects/thuma-mina-9d738/messages:send';

    // Construct the message payload
    Map<String, dynamic> message = {
      "message": {
        "token": token,
        "notification": {"title": title, "body": msg},
        // "data": {
        //   "click_action": "FLUTTER_NOTIFICATION_CLICK",
        //   "id": "1",
        //   "status": "done"
        // }
      }
    };

    // Send the POST request
    try {
      final response = await client.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(message),
      );

      print(response.body);

      print(response.statusCode);
      if (response.statusCode == 200) {
      } else {}
      // ignore: empty_catches
    } catch (e) {}

    // Close the client
    client.close();
  }
}
