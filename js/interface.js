var statusElement = document.getElementById('status');
var progressElement = document.getElementById('progress');
var spinnerElement = document.getElementById('spinner');

// We have an input buffer that is the list of new lines.
var inputBuffer = [];
var inputBox = document.getElementById('consoleInput');

window.onload = function () {
    inputBox.onkeyup = function (evt) {
        evt = evt || window.event;

        if (evt.keyCode == 13) {
            inputBuffer.push(inputBox.value);
            inputBox.value = "";
        }
    }
}

var Module = {
    preRun: (function () {
        function stdin() {
            // If we have nothing to send, no stdin data.
            if (inputBuffer.length == 0) {
                return null;
            }

            // Fetch the input string.
            var inputString = inputBuffer[0];
            if (inputString.length > 1) {
                inputBuffer[0] = inputBuffer[0].substring(1, inputBuffer[0].length - 1)
                return inputString.charCodeAt(0);
            } else if (inputString.length == 1) {
                inputBuffer.pop(0);
                return inputString.charCodeAt(0);
            }

            return null;
        }
        var stdoutBuffer = "";

        function stdout(code) {
           if (code === "\n".charCodeAt(0) && stdoutBuffer !== "") {
              console.log(stdoutBuffer);
              stdoutBuffer = "";
           } else {
              stdoutBuffer += String.fromCharCode(code);
           }
        }
  
        var stderrBuffer = "";
  
        function stderr(code) {
           if (code === "\n".charCodeAt(0) && stderrBuffer !== "") {
              console.log(stderrBuffer);
              stderrBuffer = "";
           } else {
              stderrBuffer += String.fromCharCode(code);
           }
        }

        // Only override stdin, not out/error
        FS.init(stdin, stdout, stderr);
    })(),
    postRun: [],
    print: (function () {
        var element = document.getElementById('output');
        if (element) element.value = ''; // clear browser cache
        return function (text) {
            if (arguments.length > 1) text = Array.prototype.slice.call(arguments).join(' ');
            // These replacements are necessary if you render to raw HTML
            //text = text.replace(/&/g, "&amp;");
            //text = text.replace(/</g, "&lt;");
            //text = text.replace(/>/g, "&gt;");
            //text = text.replace('\n', '<br>', 'g');
            console.log(text);
            if (element) {
                element.value += text + "\n";
                element.scrollTop = element.scrollHeight; // focus on bottom
            }
        };
    })(),
    canvas: (function () {
        var canvas = document.getElementById('canvas');

        // As a default initial behavior, pop up an alert when webgl context is lost. To make your
        // application robust, you may want to override this behavior before shipping!
        // See http://www.khronos.org/registry/webgl/specs/latest/1.0/#5.15.2
        canvas.addEventListener("webglcontextlost", function (e) { alert('WebGL context lost. You will need to reload the page.'); e.preventDefault(); }, false);

        return canvas;
    })(),
    setStatus: function (text) {
        if (!Module.setStatus.last) Module.setStatus.last = { time: Date.now(), text: '' };
        if (text === Module.setStatus.last.text) return;
        var m = text.match(/([^(]+)\((\d+(\.\d+)?)\/(\d+)\)/);
        var now = Date.now();
        if (m && now - Module.setStatus.last.time < 30) return; // if this is a progress update, skip it if too soon
        Module.setStatus.last.time = now;
        Module.setStatus.last.text = text;
        if (m) {
            text = m[1];
            progressElement.value = parseInt(m[2]) * 100;
            progressElement.max = parseInt(m[4]) * 100;
            progressElement.hidden = false;
            spinnerElement.hidden = false;
        } else {
            progressElement.value = null;
            progressElement.max = null;
            progressElement.hidden = true;
            if (!text) spinnerElement.hidden = true;
        }
        statusElement.innerHTML = text;
    },
    totalDependencies: 0,
    monitorRunDependencies: function (left) {
        this.totalDependencies = Math.max(this.totalDependencies, left);
        Module.setStatus(left ? 'Preparing... (' + (this.totalDependencies - left) + '/' + this.totalDependencies + ')' : 'All downloads complete.');
    },
    noInitialRun: true
};
Module.setStatus('Downloading...');
window.onerror = function () {
    Module.setStatus('Exception thrown, see JavaScript console');
    spinnerElement.style.display = 'none';
    Module.setStatus = function (text) {
        if (text) Module.printErr('[post-exception status] ' + text);
    };
};