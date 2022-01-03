var inputBuffer = []

window.onload = function () {
    var term = new Terminal();
    term.open(document.getElementById('terminal'));

    term.onKey((key, ev) => {
        if (key.domEvent.keyCode === 13) {
            term.write('\n');
        }
        inputBuffer.push(key.key)
        term.write(key.key);
    });

    var Module = {
        preRun: (function () {

            function stdin() {
                // If we have nothing to send, no stdin data.
                console.log("stdin requested")
                if (inputBuffer.length == 0) {
                    return null;
                }

                return String.toCharCode(inputBuffer.pop(0));
            }

            function stdout(code) {
                if (code == null) {
                    term.write('\n');
                } else {
                    term.write(String.fromCharCode(code));
                }
            }

            function stderr(code) {
                if (code == null) {
                    term.write('\n');
                } else {
                    term.write(String.fromCharCode(code));
                }
            }

            // Only override stdin, not out/error
            FS.init(stdin, stdout, stderr);
        })(),
        postRun: [],
        canvas: (function () {
            var canvas = document.getElementById('canvas');

            // As a default initial behavior, pop up an alert when webgl context is lost. To make your
            // application robust, you may want to override this behavior before shipping!
            // See http://www.khronos.org/registry/webgl/specs/latest/1.0/#5.15.2
            canvas.addEventListener("webglcontextlost", function (e) { alert('WebGL context lost. You will need to reload the page.'); e.preventDefault(); }, false);

            return canvas;
        })(),
        totalDependencies: 0,
        noInitialRun: true
    };

}
