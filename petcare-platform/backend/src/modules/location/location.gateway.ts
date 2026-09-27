import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  MessageBody,
  ConnectedSocket,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { PrismaService } from '../../common/prisma.module';

// Both apps join room `booking:<id>` once a booking is ACCEPTED.
// Provider app emits 'location:update' periodically (e.g. every 5s while
// job is in progress); user app just listens for 'location:broadcast'.
// If the booking has a safe zone set, every ping is checked against it and
// an 'location:alert' event is broadcast to the room on breach/return.
@WebSocketGateway({ cors: { origin: '*' }, namespace: 'location' })
export class LocationGateway {
  @WebSocketServer() server: Server;

  // Tracks last-known inside/outside state per booking so we only emit an
  // alert on the transition, not on every single ping.
  private lastInsideState = new Map<string, boolean>();

  constructor(private prisma: PrismaService) {}

  @SubscribeMessage('joinBooking')
  onJoin(@ConnectedSocket() client: Socket, @MessageBody() bookingId: string) {
    client.join(`booking:${bookingId}`);
  }

  @SubscribeMessage('location:update')
  async onLocationUpdate(
    @MessageBody() data: { bookingId: string; lat: number; lng: number },
  ) {
    await this.prisma.locationPing.create({
      data: { bookingId: data.bookingId, lat: data.lat, lng: data.lng },
    });

    this.server.to(`booking:${data.bookingId}`).emit('location:broadcast', {
      lat: data.lat,
      lng: data.lng,
      at: new Date().toISOString(),
    });

    await this.checkSafeZone(data.bookingId, data.lat, data.lng);
  }

  private async checkSafeZone(bookingId: string, lat: number, lng: number) {
    const booking = await this.prisma.booking.findUnique({ where: { id: bookingId } });
    if (!booking?.safeZoneLat || !booking?.safeZoneLng || !booking?.safeZoneRadiusM) return;

    const distanceM = haversineMeters(lat, lng, booking.safeZoneLat, booking.safeZoneLng);
    const isInside = distanceM <= booking.safeZoneRadiusM;
    const wasInside = this.lastInsideState.get(bookingId) ?? true;

    if (isInside !== wasInside) {
      this.lastInsideState.set(bookingId, isInside);
      this.server.to(`booking:${bookingId}`).emit('location:alert', {
        inside: isInside,
        distanceM: Math.round(distanceM),
        radiusM: booking.safeZoneRadiusM,
      });
    }
  }
}

// Standard great-circle distance between two lat/lng points, in meters.
function haversineMeters(lat1: number, lng1: number, lat2: number, lng2: number): number {
  const R = 6371000;
  const toRad = (d: number) => (d * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) ** 2;
  return 2 * R * Math.asin(Math.sqrt(a));
}
