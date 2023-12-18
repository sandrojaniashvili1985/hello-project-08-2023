import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { SettingsController } from './settings.controller';
import { ScenariosController } from './scenarios.controller';
import './schemas/settings.schema';
import './schemas/scenario.schema';
import './schemas/result.schema';
import './schemas/settings.schema';
import mongoose from 'mongoose';

// mongoose.connect(process.env.MONGODB_URI || 'mongodb+srv://aaa123:bbb123@cluster0.q7kqes9.mongodb.net/Cluster0?retryWrites=true&w=majority');
mongoose.connect(process.env.MONGODB_URI || 'mongodb+srv://aaa123:bbb123@cluster0.q7kqes9.mongodb.net/Cluster0?retryWrites=true&w=majority');

@Module({
  imports: [],
  controllers: [AppController, SettingsController, ScenariosController],
  providers: [AppService],
})
export class AppModule {}
