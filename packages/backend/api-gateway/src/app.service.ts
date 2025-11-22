import { Injectable } from '@nestjs/common';

@Injectable()
export class AppService {
  private readonly startTime = Date.now();

  getHealth(): { status: string; message: string } {
    return {
      status: 'ok',
      message: 'Ghost Protocol API Gateway is running',
    };
  }

  getDetailedHealth(): {
    status: string;
    timestamp: string;
    uptime: number;
  } {
    return {
      status: 'ok',
      timestamp: new Date().toISOString(),
      uptime: Date.now() - this.startTime,
    };
  }
}
