import axios from 'axios';

const apiClient = axios.create({
  baseURL: 'http://84.201.165.29:5000/',
  headers: {
    'Content-Type': 'application/json',
  },
});

/* data - объект задачи с единственным полем `title` */

export function createTask(data) {
    return apiClient.post('/tasks', data);
}

export function readTasks() {
    return apiClient.get('/tasks');
}

export function updateTask(id, data) {
    return apiClient.put(`/tasks/${id}`, data);
}

export function deleteTask(id) {
    return apiClient.delete(`/tasks/${id}`);
}
