import { Body, Controller, Get, Param, Post } from '@nestjs/common';
import ScenarioModel, { ScenarioDocument } from './schemas/scenario.schema';
import ResultModel, { ResultDocument } from './schemas/result.schema';

interface ScenarioWithResult extends ScenarioDocument {
  lastResult?: ResultDocument;
}

@Controller()
export class ScenariosController {
  @Get('/api/scenarios')
  async getScenarios(): Promise<ScenarioWithResult[]> {
    const items: ScenarioWithResult[] = (await ScenarioModel.find({})
      .lean()
      .exec()) as ScenarioWithResult[];

    await Promise.all(
      items.map(async (item) => {
        item.lastResult = await ResultModel.findOne({ scenario: item._id })
          .sort('-created')
          .exec();
      }),
    );

    return items;
  }

  @Post('/api/scenarios')
  async setScenarios(@Body() body): Promise<ScenarioDocument> {
    const item = new ScenarioModel(body);
    await item.save();
    return item;
  }

  @Get('/api/scenarios/:id')
  getScenario(@Param('id') _id: string): Promise<ScenarioDocument> {
    return ScenarioModel.findOne({ _id }).exec();
  }

  @Post('/api/scenarios/:id/result')
  async setScenarioResult(
    @Param('id') scenario: string,
    @Body() body,
  ): Promise<string> {
    const item = new ResultModel({
      ...body,
      scenario,
    });
    await item.save();
    return 'ok';
  }
}
