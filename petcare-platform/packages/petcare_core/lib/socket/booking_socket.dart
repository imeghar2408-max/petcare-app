import 'package:socket_io_client/socket_io_client.dart' as io;

/// Connects to one of the backend's Socket.IO namespaces (`/location` or
/// `/chat`) and joins the room for a specific booking. Both apps use this
/// the same way — only which namespace and which events they listen for
/// differs.
class BookingSocket {
  late final io.Socket socket;

  BookingSocket({required String baseUrl, required String namespace, required String bookingId}) {
    socket = io.io(
      '$baseUrl/$namespace',
      io.OptionBuilder().setTransports(['websocket']).disableAutoConnect().build(),
    );
    socket.connect();
    socket.onConnect((_) => socket.emit('joinBooking', bookingId));
  }

  void dispose() {
    socket.dispose();
  }
}
