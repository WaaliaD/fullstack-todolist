import { Body, Controller, Delete, Get, Param, Post, Put } from '@nestjs/common';
import { CreateTaskDto } from './dto/create-task.dto';
import { TasksService } from './tasks.service';

@Controller('tasks')
export class TasksController {

    constructor(private tasksService: TasksService) {}

    @Post()
    create(@Body() taskDto: CreateTaskDto) {
        return this.tasksService.create(taskDto);
    }
    
    @Get()
    read() {
        return this.tasksService.read();
    }
    
    @Put(':id')
    update(@Param('id') id: number, @Body() taskDto: CreateTaskDto) {
        return this.tasksService.update(id, taskDto);
    }
    
    @Delete(':id')
    delete(@Param('id') id: number) {
        return this.tasksService.delete(id);
    }
}
