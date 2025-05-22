import { Module } from "@nestjs/common";
import { SequelizeModule } from "@nestjs/sequelize";
import { TasksModule } from './tasks/tasks.module';
import { ConfigModule } from "@nestjs/config";
import { Task } from "./tasks/tasks.model";
import * as fs from 'fs';
import * as path from 'path';

@Module({
  controllers: [],
  providers: [],
  imports: [
    ConfigModule.forRoot({
      envFilePath: '.env',
    }),
    SequelizeModule.forRoot({
      dialect: 'postgres',
      host: process.env.POSTGRES_HOST,
      port: Number(process.env.POSTGRES_PORT),
      username: process.env.POSTGRES_USER,
      password: process.env.POSTGRES_PASSWORD,
      database: process.env.POSTGRES_DB,
      models: [Task],
      autoLoadModels: true,
      dialectOptions: {
        ssl: {
          require: true,
          rejectUnauthorized: true,
          ca: fs.readFileSync(path.resolve(__dirname, '..', 'root.crt')).toString(),
        },
      },
    }),
    TasksModule,
  ],
})
export class AppModule {}