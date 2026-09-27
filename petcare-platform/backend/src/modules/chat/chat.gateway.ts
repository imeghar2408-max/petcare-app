import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  MessageBody,
  ConnectedSocket,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { PrismaService } from '../../common/prisma.module';

@WebSocketGateway({ cors: { origin: '*' }, namespace: 'chat' })
export class ChatGateway {
  @WebSocketServer() server: Server;

  constructor(private prisma: PrismaService) {}

  @SubscribeMessage('joinBooking')
  onJoin(@ConnectedSocket() client: Socket, @MessageBody() bookingId: string) {
    client.join(`booking:${bookingId}`);
  }

  @SubscribeMessage('message:send')
  async onMessage(
    @MessageBody() data: { bookingId: string; senderId: string; text: string },
  ) {
    const message = await this.prisma.chatMessage.create({ data });
    this.server.to(`booking:${data.bookingId}`).emit('message:new', message);
    // TODO: if recipient is offline, send FCM push with message preview.
  }
}
