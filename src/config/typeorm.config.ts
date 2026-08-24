import { ConfigService } from '@nestjs/config';
import { TypeOrmModuleOptions } from '@nestjs/typeorm';
import { join } from 'path';

const getDatabasePort = (configService: ConfigService): number => {
  const port = Number(configService.get<string>('MYSQL_PORT', '3306'));

  if (!Number.isInteger(port) || port < 1 || port > 65535) {
    throw new Error('MYSQL_PORT must be an integer between 1 and 65535.');
  }

  return port;
};

export const createTypeormConnectionConfig = (
  configService: ConfigService,
): TypeOrmModuleOptions => ({
  type: 'mysql',
  host: configService.get<string>('MYSQL_HOST'),
  port: getDatabasePort(configService),
  username: configService.get<string>('MYSQL_USER'),
  password: configService.get<string>('MYSQL_PASSWORD'),
  database: configService.get<string>('MYSQL_DATABASE'),
  entities: [join(__dirname, '..', '**', '*.entity.{js,ts}')],
  synchronize: configService.get<string>('NODE_ENV') !== 'production',
  timezone: 'Z',
});
