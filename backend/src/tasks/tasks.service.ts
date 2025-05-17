import { Injectable } from '@nestjs/common';
import { Task } from './tasks.model';
import { CreateTaskDto } from './dto/create-task.dto';
import { InjectModel } from '@nestjs/sequelize';

@Injectable()
export class TasksService {

    constructor(@InjectModel(Task) private taskRepository: typeof Task) {}

    async create(dto: CreateTaskDto) {
        const task = await this.taskRepository.create(dto);
        return task;
    }

    async read() {
        const tasks = await this.taskRepository.findAll();
        return tasks;
    }

    async update(id: number, dto: CreateTaskDto) {
        const task = await this.taskRepository.findByPk(id);
        if (!task) {
            throw new Error('Task not found');
        }
        await task.update(dto);
        return task;
    }

    async delete(id: number) {
        const task = await this.taskRepository.findByPk(id);
        if (!task) {
            throw new Error('Task not found');
        }
        await task.destroy();
        return { message: 'Task deleted successfully' };
    }
}
