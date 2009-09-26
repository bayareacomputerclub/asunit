package asunit.textui {
    import asunit.errors.AssertionFailedError;
    import asunit.framework.Test;
    import asunit.framework.TestFailure;
    import asunit.framework.TestListener;
    import asunit.framework.TestResult;
    import asunit.runner.BaseTestRunner;
    import asunit.runner.Version;

    import flash.display.Sprite;
    import flash.events.*;
    import flash.system.Capabilities;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import flash.utils.getTimer;
    import flash.utils.setInterval;
    import flash.utils.setTimeout;

    /**
    *   This is the base class for collecting test output and formatting for different
    *   displays.
    *
    *   This class simply presents test results as if they were being shown on a terminal.
    *
    *   The <code>XMLResultPrinter</code> provides a good example of how this class can
    *   be subclassed and used to emit different/additional output.
    *
    *   @see XMLResultPrinter
    **/
    public class ResultPrinter extends Sprite implements TestListener {
        private var fColumn:int = 0;
        private var textArea:TextField;
		private var defaultFormat:TextFormat;
        private var gutter:uint = 0;
        private var backgroundColor:uint = 0x333333;
        private var bar:SuccessBar;
        private var barHeight:Number = 3;
        private var showTrace:Boolean;
        protected var startTime:Number;
        protected var testTimes:Array;

        public function ResultPrinter(showTrace:Boolean = false) {
            this.showTrace = showTrace;
            testTimes = new Array();
            configureAssets();
            println();

            // Create a loop so that the FDBTask
            // can halt execution properly:
            setInterval(function():void {
            }, 500);
        }

        private function configureAssets():void {
            textArea = new TextField();
            textArea.background = true;
            textArea.backgroundColor = backgroundColor;
            textArea.border = true;
            textArea.wordWrap = true;
			textArea.multiline = true;
            defaultFormat = new TextFormat();
            defaultFormat.font = "Verdana";
            defaultFormat.size = 10;
            defaultFormat.color = 0xFFFFFF;
            textArea.defaultTextFormat = defaultFormat;
            addChild(textArea);
            println("AsUnit " + Version.id() + " by Luke Bayes and Ali Mills");
            println("");
            println("Flash Player version: " + Capabilities.version);

            bar = new SuccessBar();
            addChild(bar);
        }

        public function setShowTrace(showTrace:Boolean):void {
            this.showTrace = showTrace;
        }

        public override function set width(w:Number):void {
            textArea.x = gutter;
            textArea.width = w - gutter*2;
            bar.x = gutter;
            bar.width = textArea.width;
        }

        public override function set height(h:Number):void {
            textArea.height = h - ((gutter*2) + barHeight);
            textArea.y = gutter;
            bar.y = h - (gutter + barHeight);
            bar.height = barHeight;
        }

        public function println(...args:Array):void {
            textArea.appendText(args.toString() + "\n");
            //textArea.htmlText += '<p>' + (args.toString()) + '</p>';
        }

        public function print(...args:Array):void {
            textArea.appendText(args.toString());
            //textArea.htmlText += (args.toString());
        }
		
		protected function printHtml(html:String):void {
			html = '<font face="' + defaultFormat.font
				+'" size="' + defaultFormat.size
				+'" color="#' + defaultFormat.color.toString(16) +'">'
				+ html
				+ '</font>';
			textArea.htmlText += html;
		}
		
		public static function escapeHtml(html:String):String
		{
			return html.replace(/&/g, "&amp;")
				.replace(/</g, "&lt;")
				.replace(/>/g, "&gt;")
				.replace(/"/g, "&quot;");
		}

        /**
         * API for use by textui.TestRunner
         */

        public function run(test:Test):void {
        }

        public function printResult(result:TestResult, runTime:Number):void {
            printHeader(runTime);
            printErrors(result);
            printFailures(result);
            printFooter(result);

               bar.setSuccess(result.wasSuccessful());
               if(showTrace) {
                trace(textArea.text.split("\r").join("\n"));
               }
        }

        /* Internal methods
         */
        protected function printHeader(runTime:Number):void {
            println();
            println();
            println("Time: " + elapsedTimeAsString(runTime));
        }

        protected function printErrors(result:TestResult):void {
            printDefects(result.errors(), result.errorCount(), "error");
        }

        protected function printFailures(result:TestResult):void {
            printDefects(result.failures(), result.failureCount(), "failure");
        }

        protected function printDefects(booBoos:Object, count:int, type:String):void {
            if (count == 0) {
                return;
            }
            if (count == 1) {
                println("There was " + count + " " + type + ":");
            }
            else {
                println("There were " + count + " " + type + "s:");
            }
            var i:uint;
            for each (var item:TestFailure in booBoos) {
                printDefect(TestFailure(item), i);
                i++;
            }
        }

        public function printDefect(booBoo:TestFailure, count:int ):void { // only public for testing purposes
            printDefectHeader(booBoo, count);
            printDefectTrace(booBoo);
        }

        protected function printDefectHeader(booBoo:TestFailure, count:int):void {
            // I feel like making this a println, then adding a line giving the throwable a chance to print something
            // before we get to the stack trace.
            var startIndex:uint = textArea.text.length;
			println();
            println(count + ") " + booBoo.failedFeature());
            var endIndex:uint = textArea.text.length;

            var format:TextFormat = textArea.defaultTextFormat;
            format.bold = true;

            // GROSS HACK because of bug in flash player - TextField isn't accepting formats...
            //setTimeout(onFormatTimeout, 1, format, startIndex, endIndex);
			
			// Looks like the HACK isn't necessary anymore.
            textArea.setTextFormat(format, startIndex, endIndex);
        }

        public function onFormatTimeout(format:TextFormat, startIndex:uint, endIndex:uint):void {
            textArea.setTextFormat(format, startIndex, endIndex);
        }

        protected function printDefectTrace(booBoo:TestFailure):void {
            var stack:String = BaseTestRunner.getFilteredTrace(booBoo.thrownException().getStackTrace());
			stack = escapeHtml(stack);
			var method:String = booBoo.failedMethod();
			stack = stack.replace(new RegExp(method, 'g'), '<font color="#FFAAAA"><b>' + method + '</b></font>');
			stack += '<br>';
			//printHtml('<p>'+stack+'</p>');
			printHtml(stack);
        }
		
        protected function printFooter(result:TestResult):void {
            println();
            if (result.wasSuccessful()) {
                print("OK");
                println (" (" + result.runCount() + " test" + (result.runCount() == 1 ? "": "s") + ")");
            } else {
                println("FAILURES!!!");
                println("Tests run: " + result.runCount()+
                             ",  Failures: "+result.failureCount()+
                             ",  Errors: "+result.errorCount());
            }

            printTimeSummary();
            println();
        }

        protected function printTimeSummary():void {
            testTimes.sortOn('duration', Array.NUMERIC | Array.DESCENDING);
            println();
            println();
            println('Time Summary:');
            println();
            var len:Number = testTimes.length;
            for(var i:Number = 0; i < len; i++) {
                println(testTimes[i].toString());
            }
        }

        /**
         * Returns the formatted string of the elapsed time.
         * Duplicated from BaseTestRunner. Fix it.
         */
        protected function elapsedTimeAsString(runTime:Number):String {
            return Number(runTime/1000).toString();
        }

        /**
         * @see asunit.framework.TestListener#addError(Test, Throwable)
         */
        public function addError(test:Test, t:Error):void {
            print("E");
        }

        /**
         * @see asunit.framework.TestListener#addFailure(Test, AssertionFailedError)
         */
        public function addFailure(test:Test, t:AssertionFailedError):void {
            print("F");
        }

        /**
         * @see asunit.framework.TestListener#endTestMethod(test, testMethod);
         */
        public function startTestMethod(test:Test, methodName:String):void {
        }

        /**
         * @see asunit.framework.TestListener#endTestMethod(test, testMethod);
         */
        public function endTestMethod(test:Test, methodName:String):void {
        }

        /**
         * @see asunit.framework.TestListener#startTest(Test)
         */
        public function startTest(test:Test):void {
            startTime = getTimer();
            var count:uint = test.countTestCases();
            for(var i:uint; i < count; i++) {
                print(".");
                if (fColumn++ >= 80) {
                    println();
                    fColumn = 0;
                }
            }
        }

        /**
         * @see asunit.framework.TestListener#endTest(Test)
         */
        public function endTest(test:Test):void {
            var duration:Number = getTimer() - startTime;
            testTimes.push(TestTime.create(test, duration));
        }
    }
}

import flash.display.Sprite;

class SuccessBar extends Sprite {
    private var myWidth:uint;
    private var myHeight:uint;
    private var bgColor:uint;
    private var passingColor:uint = 0x00FF00;
    private var failingColor:uint = 0xFD0000;

    public function SuccessBar() {
    }

    public function setSuccess(success:Boolean):void {
        bgColor = (success) ? passingColor : failingColor;
        draw();
    }

    public override function set width(num:Number):void {
        myWidth = num;
        draw();
    }

    public override function set height(num:Number):void {
        myHeight = num;
        draw();
    }

    private function draw():void {
        graphics.clear();
        graphics.beginFill(bgColor);
        graphics.drawRect(0, 0, myWidth, myHeight);
        graphics.endFill();
    }
}
