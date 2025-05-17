<script setup>
import { ref, onMounted } from 'vue'
import { createTask, readTasks, updateTask, deleteTask } from './api'

const tasks = ref([])
const newTaskTitle = ref('')
const editingTaskId = ref(null)
const editedTitle = ref('')

// Загрузка задач при монтировании
onMounted(async () => {
  await fetchTasks()
})

// Получение списка задач
async function fetchTasks() {
  try {
    const response = await readTasks()
    tasks.value = response.data
  } catch (error) {
    console.error('Ошибка при загрузке задач:', error)
  }
}

// Создание новой задачи
async function addTask() {
  if (!newTaskTitle.value.trim()) return
  
  try {
    await createTask({ title: newTaskTitle.value })
    newTaskTitle.value = ''
    await fetchTasks()
  } catch (error) {
    console.error('Ошибка при создании задачи:', error)
  }
}

// Начало редактирования задачи
function startEdit(task) {
  editingTaskId.value = task.id
  editedTitle.value = task.title
}

// Сохранение изменений
async function saveEdit(id) {
  try {
    await updateTask(id, { title: editedTitle.value })
    editingTaskId.value = null
    await fetchTasks()
  } catch (error) {
    console.error('Ошибка при обновлении задачи:', error)
  }
}

// Отмена редактирования
function cancelEdit() {
  editingTaskId.value = null
}

// Удаление задачи
async function removeTask(id) {
  try {
    await deleteTask(id)
    await fetchTasks()
  } catch (error) {
    console.error('Ошибка при удалении задачи:', error)
  }
}
</script>

<template>
  <main class="container">
    <h1>Менеджер задач</h1>
    
    <div class="form">
      <input 
        v-model="newTaskTitle" 
        type="text" 
        placeholder="Текст задачи"
        @keyup.enter="addTask"
      />
      <button @click="addTask">Создать задачу</button>
    </div>

    <ul class="task-list">
      <li v-for="task in tasks" :key="task.id" class="task-item">
        <div v-if="editingTaskId !== task.id" class="task-view">
          <span>{{ task.title }}</span>
          <div class="task-actions">
            <button @click="startEdit(task)">✏️</button>
            <button @click="removeTask(task.id)">🗑️</button>
          </div>
        </div>
        
        <div v-else class="task-edit">
          <input v-model="editedTitle" type="text" @keyup.enter="saveEdit(task.id)"/>
          <div class="edit-actions">
            <button @click="saveEdit(task.id)">✅</button>
            <button @click="cancelEdit">❌</button>
          </div>
        </div>
      </li>
    </ul>
  </main>
</template>

<style>
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
  font-family: Arial, sans-serif;
}

.container {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 2rem;
  max-width: 800px;
  margin: 0 auto;
}

h1 {
  margin-bottom: 2rem;
  color: #333;
}

.form {
  display: flex;
  gap: 15px;
  margin-bottom: 2rem;
  width: 100%;
}

.form input {
  flex-grow: 1;
  padding: 0.5rem;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 1rem;
}

button {
  padding: 0.5rem 1rem;
  background-color: #42b983;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-size: 1rem;
  transition: background-color 0.2s;
}

button:hover {
  background-color: #369f6e;
}

.task-list {
  list-style: none;
  width: 100%;
}

.task-item {
  padding: 1rem;
  border: 1px solid #eee;
  border-radius: 4px;
  margin-bottom: 0.5rem;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.task-view {
  display: flex;
  justify-content: space-between;
  align-items: center;
  width: 100%;
}

.task-actions {
  display: flex;
  gap: 0.5rem;
}

.task-actions button {
  background-color: transparent;
  color: #333;
  padding: 0.2rem;
}

.task-edit {
  display: flex;
  gap: 0.5rem;
  width: 100%;
}

.task-edit input {
  flex-grow: 1;
  padding: 0.5rem;
  border: 1px solid #ddd;
  border-radius: 4px;
}

.edit-actions {
  display: flex;
  gap: 0.5rem;
}

.edit-actions button {
  background-color: transparent;
  color: #333;
  padding: 0.2rem;
}
</style>