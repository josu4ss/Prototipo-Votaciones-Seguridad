import 'reflect-metadata';
import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule, { cors: false });
  app.setGlobalPrefix('api');
  app.useGlobalPipes(new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true }));
  app.enableShutdownHooks();
  // En localhost para el emulador Android: 10.0.2.2 -> máquina anfitriona.
  await app.listen(Number(process.env.PORT || 3000), process.env.BIND_HOST || '127.0.0.1');
  console.log(`API de demostración iniciada en puerto ${process.env.PORT || 3000}`);
}
bootstrap();
