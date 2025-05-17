import { Column, DataType, Model, Table } from "sequelize-typescript";

interface TaskCreationAttrs {
    title: string;
}

@Table({tableName: 'tasks'})
export class Task extends Model<Task,TaskCreationAttrs> {
    @Column({type: DataType.INTEGER, unique: true, autoIncrement: true, primaryKey: true})
    declare id: number;
    @Column({type: DataType.STRING, allowNull: false})
    declare title: string;
}