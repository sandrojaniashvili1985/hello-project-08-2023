import { Body, Controller, Get, Post } from '@nestjs/common';
import SettingsModel, { SettingsDocument } from './schemas/settings.schema';

@Controller()
export class SettingsController {
  @Get('/api/settings')
  async getSettings(): Promise<SettingsDocument> {
    const settings = await SettingsModel.findOne({});

    return settings || new SettingsModel();
  }

  @Post('/api/settings')
  async setSettings(@Body() body: any): Promise<SettingsDocument> {
    let settings = await SettingsModel.findOne({});
    if (!settings) {
      settings = new SettingsModel(body);
    } else {
      Object.assign(settings, body);
    }
    await settings.save();
    return settings;
  }
}
