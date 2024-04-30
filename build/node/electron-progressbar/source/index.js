'use strict';

const BrowserWindow = require('electron').BrowserWindow;

// use 'extend' because 'Object.assign' doesn't work for deep copy
const extend = require('extend');

class ProgressBar {
	constructor(options, electronApp) {
		this._defaultOptions = {
			abortOnError: false,
			debug: false,
			
			indeterminate: true,
			initialValue: 0,
			maxValue: 100,
			closeOnComplete: true,
			title: 'Wait...',
			text: 'Wait...',
			detail: null,
			
			style: {
				text: {},
				detail: {},
				bar: {
					'width': '100%',
					'background': '#BBE0F1'
				},
				value: {
					'background': '#0976A9'
				}
			},
			
			browserWindow: {
				parent: null,
				modal: true,
				resizable: false,
				closable: false,
				minimizable: false,
				maximizable: false,
				width: 500,
				height: 170
			}
		};
		
		this._styleSelector = {
			determinate: {
				text: '#text',
				detail: '#detail',
				bar: '#progressBar::-webkit-progress-bar',
				value: '#progressBar::-webkit-progress-value'
			},
			indeterminate: {
				text: '#text',
				detail: '#detail',
				bar: '#progressBar[indeterminate="t"]',
				value: '#progressBar[indeterminate="t"] #progressBarValue'
			}
		};
		
		this._callbacks = {
			'ready': [], // list of function(){}
			'progress': [], // list of function(value){}
			'completed': [], // list of function(value){}
			'aborted': [] // list of function(value){}
		};
		
		this._inProgress = true;
		this._options = this._parseOptions(options);
		this._realValue = this._options.initialValue;
		this._window = null;
		
		if (electronApp) {
			if (electronApp.isReady()) {
				this._createWindow();
			} else {
				electronApp.on('ready', () => this._createWindow.call(this));
			}
		} else {
			this._createWindow();
		}
	}
	
	get value() {
		return this._options.indeterminate ? null : this._realValue;
	}
	
	get text() {
		return this._options.text;
	}
	
	get detail() {
		return this._options.detail;
	}
	
	set title(title) {
		if (this._window) {
			this._window.setTitle(title);
		}
	}
	
	set value(value) {
		if (!this._window) {
			return this._error('Invalid call: trying to set value but the progress bar window is not active.');
		}
		
		if (!this.isInProgress()) {
			return this._error('Invalid call: trying to set value but the progress bar is already completed.');
		}
		
		if (this._options.indeterminate) {
			return this._error('Invalid call: setting value on an indeterminate progress bar is not allowed.');
		}
		
		if (typeof value != 'number') {
			return this._error(`Invalid call: 'value' must be of type 'number' (type found: '` + (typeof value) + `').`);
		}
		
		this._realValue = Math.max(this._options.initialValue, value);
		this._realValue = Math.min(this._options.maxValue, this._realValue);
		
		this._window.webContents.send('SET_PROGRESS', this._realValue);
		
		this._updateTaskbarProgress();
		
		this._fire('progress', [this._realValue]);
		
		this._execWhenCompleted();
	}
	
	set text(text) {
		this._options.text = text;
		this._window.webContents.send('SET_TEXT', text);
	}
	
	set detail(detail) {
		this._options.detail = detail;
		this._window.webContents.send('SET_DETAIL', detail);
	}
	
	getOptions() {
		return extend({}, this._options);
	}
	
	on(event, callback) {
		this._callbacks[event].push(callback);
		return this;
	}
	
	setCompleted() {
		if (!this.isInProgress()) {
			return;
		}
		
		this._realValue = this._options.maxValue;
		
		if (!this._options.indeterminate) {
			this._window.webContents.send('SET_PROGRESS', this._realValue);
		}
		
		this._updateTaskbarProgress();
		
		this._execWhenCompleted();
	}
	
	close() {
		if (!this._window || this._window.isDestroyed()) {
			return;
		}
		
		this._window.destroy();
	}
	
	isInProgress() {
		return this._inProgress;
	}
	
	isCompleted() {
		return this._realValue >= this._options.maxValue;
	}
	
	_error(message) {
		if (this._options.abortOnError) {
			if (this._window && !this._window.isDestroyed()) {
				this._window && this._window.destroy();
			}
			
			throw Error(message);
		} else {
			console.warn(message);
		}
	}
	
	_fire(event, params) {
		this._callbacks[event] && this._callbacks[event].forEach(cb => {
			cb.apply(cb, params || []);
		});
	}
	
	_parseOptions(originalOptions) {
		let options = extend(true, {}, this._defaultOptions, originalOptions);
		
		if (options.indeterminate) {
			options.initialValue = 0;
			options.maxValue = 100;
		}
		
		if (options.title && !options.browserWindow.title) {
			options.browserWindow.title = options.title;
		}
		
		return options;
	}
	
	_parseStyle() {
		let style = [];
		let styleSelector = this._styleSelector[this._options.indeterminate ? 'indeterminate' : 'determinate'];
		
		Object.keys(styleSelector).forEach(el => {
			if (!styleSelector[el]) {
				return;
			}
			
			style.push(`${styleSelector[el]}{`);
			for (let prop in this._options.style[el]) {
				style.push(`${prop}:${this._options.style[el][prop]} !important;`);
			}
			style.push(`}`);
		});
		
		if (this._options.indeterminate) {
			if (this._options.style && this._options.style.value && this._options.style.value.background) {
				style.push(`
					.completed${this._styleSelector.indeterminate.bar},
					.completed${this._styleSelector.indeterminate.value}{
						background: ${this._options.style.value.background} !important;
					}
				`);
			}
		}
		
		return style.join('');
	}
	
	_createWindow() {
		this._window = new BrowserWindow(this._options.browserWindow);
		
		this._window.setMenu(null);
		
		if(this._options.debug){
			this._window.webContents.openDevTools({mode: 'detach'});
		}
		
		this._window.on('closed', () => {
			this._inProgress = false;
			this._window = null;
			
			if (this._realValue < this._options.maxValue) {
				this._fire('aborted', [this._realValue]);
			}
			
			this._updateTaskbarProgress();
		});
		
		this._window.loadURL('data:text/html;charset=UTF8,' + encodeURIComponent(htmlContent));
		
		this._window.webContents.on('did-finish-load', () => {
			if (this._options.text !== null) {
				this.text = this._options.text;
			}
			
			if (this._options.detail !== null) {
				this.detail = this._options.detail;
			}
			
			this._window.webContents.insertCSS(this._parseStyle());
			
			if (this._options.maxValue !== null) {
				this._window.webContents.send('CREATE_PROGRESS_BAR', {
					indeterminate: this._options.indeterminate,
					maxValue: this._options.maxValue
				});
			}
			
			this._fire('ready');
		});
		
		this._updateTaskbarProgress();
	}
	
	_updateTaskbarProgress() {
		let mainWindow;
		
		if (this._options.browserWindow && this._options.browserWindow.parent) {
			mainWindow = this._options.browserWindow.parent;
		} else {
			mainWindow = this._window;
		}
		
		if (!mainWindow || mainWindow.isDestroyed()) {
			return;
		}
		
		if (!this.isInProgress() || this.isCompleted()) {
			// remove the progress bar from taskbar
			return mainWindow.setProgressBar(-1);
		}
		
		if (this._options.indeterminate) {
			// any number above 1 turns the taskbar's progress bar indeterminate
			mainWindow.setProgressBar(9);
		} else {
			const percentage = (this.value * 100) / this._options.maxValue;
			
			// taskbar's progress bar must be a number between 0 and 1, e.g.:
			// 63% should be 0.63, 99% should be 0.99...
			const taskbarProgressValue = percentage / 100;
			
			mainWindow.setProgressBar(taskbarProgressValue);
		}
	}
	
	_execWhenCompleted() {
		if (!this.isInProgress() || !this.isCompleted() || !this._window || !this._window.webContents) {
			return;
		}
		
		this._inProgress = false;
		
		this._window.webContents.send('SET_COMPLETED');
		
		this._updateTaskbarProgress();
		
		this._fire('completed', [this._realValue]);
		
		if (this._options.closeOnComplete) {
			var delayToFinishAnimation = 500;
			setTimeout(() => this.close(), delayToFinishAnimation);
		}
	}
}

const htmlContent = `
<!DOCTYPE html>
<html>
	<head>
		<meta charset="UTF-8">
		<style>
			*{
				margin: 0;
				padding: 0;
				box-sizing: border-box;
			}
			
			body{
				margin: 20px;
				margin-bottom: 0;
				font: 13px normal Verdana, Arial, "sans-serif";
			}
			
			#text{
				height: 26px;
				overflow: auto;
				font-size: 14px;
				font-weight: bold;
				padding: 5px 0;
				word-break: break-all;
			}
			
			#detail{
				height: 40px;
				margin: 5px 0;
				padding: 5px 0;
				word-break: break-all;
			}
			
			#progressBarContainer{
				text-align: center;
			}
			
			progress{
				-webkit-appearance: none;
				appearance: none;
				width: 100%;
				height: 25px;
			}
			
			progress::-webkit-progress-bar{
				width: 100%;
				box-shadow: 0 2px 5px rgba(0, 0, 0, 0.25) inset;
				border-radius: 2px;
				background: #DEDEDE;
			}
			
			progress::-webkit-progress-value{
				box-shadow: 0 2px 5px rgba(0, 0, 0, 0.25) inset;
				border-radius: 2px;
				background: #22328C;
			}
			
			#progressBar[indeterminate="t"]{
				overflow: hidden;
				position: relative;
				display: block;
				margin: 0.5rem 0 1rem 0;
				width: 100%;
				height: 10px;
				border-radius: 2px;
				background-color: #DEDEDE;
				background-clip: padding-box;
			}
			
			#progressBar[indeterminate="t"] #progressBarValue::before{
				content: "";
				position: absolute;
				top: 0;
				bottom: 0;
				left: 0;
				will-change: left, right;
				background: inherit;
			}
			
			#progressBar[indeterminate="t"] #progressBarValue::before{
				-webkit-animation: indeterminate 2.1s cubic-bezier(0.65, 0.815, 0.735, 0.395) infinite;
				animation: indeterminate 2.1s cubic-bezier(0.65, 0.815, 0.735, 0.395) infinite;
			}
			
			#progressBar[indeterminate="t"] #progressBarValue::after{
				content: "";
				position: absolute;
				top: 0;
				bottom: 0;
				left: 0;
				will-change: left, right;
				background: inherit;
			}
			
			#progressBar[indeterminate="t"] #progressBarValue::after{
				-webkit-animation: indeterminate-short 2.1s cubic-bezier(0.165, 0.84, 0.44, 1) infinite;
				animation: indeterminate-short 2.1s cubic-bezier(0.165, 0.84, 0.44, 1) infinite;
				-webkit-animation-delay: 1.15s;
				animation-delay: 1.15s;
			}
			
			#progressBar[indeterminate="t"].completed #progressBarValue::before,
			#progressBar[indeterminate="t"].completed #progressBarValue::after{
				display: none;
			}
			
			.completed#progressBar[indeterminate="t"],
			.completed#progressBar[indeterminate="t"] #progressBarValue{
				-webkit-transition: 0.5s;
				transition: 0.5s;
			}
			
			@-webkit-keyframes indeterminate{
				0%{ left: -35%; right: 100%; }
				60%{ left: 100%; right: -90%; }
				100%{ left: 100%; right: -90%; }
			}
			
			@keyframes indeterminate{
				0%{ left: -35%; right: 100%; }
				60%{ left: 100%; right: -90%; }
				100%{ left: 100%; right: -90%; }
			}
			
			@-webkit-keyframes indeterminate-short{
				0%{ left: -200%; right: 100%; }
				60%{ left: 107%; right: -8%; }
				100%{ left: 107%; right: -8%; }
			}
			
			@keyframes indeterminate-short{
				0%{ left: -200%; right: 100%; }
				60%{ left: 107%; right: -8%; }
				100%{ left: 107%; right: -8%; }
			}
		</style>
	</head>
	<body>
		<div id="text"></div>
		<div id="detail"></div>
		<div id="progressBarContainer"></div>
		<script>
			var currentValue = {
				progress : null,
				text : null,
				detail : null
			};
			
			var elements = {
				text : document.querySelector("#text"),
				detail : document.querySelector("#detail"),
				progressBarContainer : document.querySelector("#progressBarContainer"),
				progressBar : null // set by createProgressBar()
			};
			
			function createProgressBar(settings){
				if(settings.indeterminate){
					var progressBar = document.createElement("div");
					progressBar.setAttribute("id", "progressBar");
					progressBar.setAttribute("indeterminate", "t");
					
					var progressBarValue = document.createElement("div");
					progressBarValue.setAttribute("id", "progressBarValue");
					progressBar.appendChild(progressBarValue);
					
					elements.progressBar = progressBar;
					elements.progressBarContainer.appendChild(elements.progressBar);
				}else{
					var progressBar = document.createElement("progress");
					progressBar.setAttribute("id", "progressBar");
					progressBar.max = settings.maxValue;
					
					elements.progressBar = progressBar;
					elements.progressBarContainer.appendChild(elements.progressBar);
				}
				
				window.requestAnimationFrame(synchronizeUi);
			}
			
			function synchronizeUi(){
				elements.progressBar.value = currentValue.progress;
				elements.text.innerHTML = currentValue.text;
				elements.detail.innerHTML = currentValue.detail;
				window.requestAnimationFrame(synchronizeUi);
			}
			
			require("electron").ipcRenderer.on("CREATE_PROGRESS_BAR", (event, settings) => {
				createProgressBar(settings);
			});
			
			require("electron").ipcRenderer.on("SET_PROGRESS", (event, value) => {
				currentValue.progress = value;
			});
			
			require("electron").ipcRenderer.on("SET_COMPLETED", (event) => {
				elements.progressBar.classList.add('completed');
			});
			
			require("electron").ipcRenderer.on("SET_TEXT", (event, value) => {
				currentValue.text = value;
			});
			
			require("electron").ipcRenderer.on("SET_DETAIL", (event, value) => {
				currentValue.detail = value;
			});
		</script>
	</body>
</html>
`;

module.exports = ProgressBar;
