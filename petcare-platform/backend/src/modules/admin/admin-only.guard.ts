import { CanActivate, ExecutionContext, ForbiddenException, Injectable } from '@nestjs/common';
import { PrismaService } from '../../common/prisma.module';

@Injectable()
export class AdminOnlyGuard implements CanActivate {
  constructor(private prisma: PrismaService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const req = context.switchToHttp().getRequest();
    const user = await this.prisma.user.findUnique({
      where: { firebaseUid: req.firebaseUser.uid },
    });
    if (user?.role !== 'ADMIN') {
      throw new ForbiddenException('Admin access only');
    }
    return true;
  }
}
