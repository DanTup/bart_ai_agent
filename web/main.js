const ws = new WebSocket('ws://' + window.location.host + '/ws');
const chat = document.getElementById('chat');
const input = document.getElementById('input');
const todoListContainer = document.getElementById('todoListContainer');
const todoListElement = document.getElementById('todoList');
const messageTemplate = document.getElementById('message-template');
const toolCallTemplate = document.getElementById('tool-call-message-template');

ws.onmessage = function (event) {
	const data = JSON.parse(event.data);
	displayMessage(data);
};

function displayMessage(message) {
	switch (message.type) {
		case 'system':
			addChatMessage('System', message.content);
			break;
		case 'user':
			addChatMessage('You', message.content);
			break;
		case 'assistant':
			addChatMessage('Bart', message.content);
			break;
		case 'working':
			addChatMessage('Bart', message.reason);
			break;
		case 'stop_working':
			removeWorkingMessages();
			break;
		case 'tool_call':
			addToolCallMessage(message.toolName);
			break;
		case 'todo_list':
			updateTodoList(message.tasks || []);
			break;
	}
}

function addMessage(template, setContent) {
	const div = template.content.cloneNode(true);
	setContent(div);
	chat.appendChild(div);
	chat.scrollTop = chat.scrollHeight;
}

function addChatMessage(participant, content) {
	addMessage(messageTemplate, (div) => {
		div.querySelector('.participant').textContent = participant;
		div.querySelector('.content').innerHTML = marked.parse(content);
		const className = participant.toLowerCase();
		div.firstElementChild.classList.add(className);
	});
}

function addToolCallMessage(toolName) {
	addMessage(toolCallTemplate, (div) => {
		div.querySelector('.tool-name').textContent = toolName;
	});
}

function removeWorkingMessages() {
	const workingDivs = chat.querySelectorAll('.working-message');
	workingDivs.forEach(d => d.remove());
}

function updateTodoList(tasks) {
	todoListElement.innerHTML = '';
	if (!tasks.length) {
		todoListContainer.classList.add('hidden');
		return;
	}

	todoListContainer.classList.remove('hidden');
	tasks.forEach(task => {
		const template = document.getElementById('todo-item-template');
		const item = template.content.cloneNode(true);
		const li = item.firstElementChild;
		const checkbox = item.querySelector('input[type="checkbox"]');
		const textSpan = item.querySelector('.task-text');

		checkbox.checked = task.isComplete;
		textSpan.textContent = task.task;
		if (task.isComplete) {
			li.classList.add('completed');
		}

		todoListElement.appendChild(li);
	});
}

function sendMessage() {
	const content = input.value.trim();
	if (content) {
		addChatMessage('You', content);
		ws.send(JSON.stringify({ type: 'input', content: content }));
		input.value = '';
	}
}

function handleKeyDown(event) {
	if (event.key === 'Enter') {
		if (event.ctrlKey || !event.shiftKey) {
			event.preventDefault();
			sendMessage();
		}
	}
}
