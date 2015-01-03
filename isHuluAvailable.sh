#!/bin/sh
sudo apt-get update;
sudo apt-get install phantomjs -y;
cat > hulu.js << EOF
#!/usr/bin/phantomjs

// grab the "rendered" HTML of a JavaScript-requiring web page

// TBD:
// add '-' as magic filename to read from STDIN
// add more curl-like switches? --or just let curl do that and consume the output of curl?
// add a switch for page.render( URLdump); // "screenshot"

var system = require('system'); // var args = require('system').args;
var page = require('webpage').create();

if (system.args.length === 1) {
    console.log('Usage: curl-phantom.js <http://URL/path/file.ext>');
    // note: can also read "pages" from the local filesystem
    phantom.exit();
} else {

var URLarg=system.args[1];
var theStatusCode = null;
var theStatusPrev = null;
var thePrevURL    = ''  ;
var theCurrURL    = ''  ;
var timestamp     = Date.now();
var verbose       = false;
var debug         = false;
var full_page     = false;
var header_key    = 'X-Forwarded-For';
var header_val    = '3.1.20.13';

for (var i=1; i<system.args.length; i++) { /* skip args[0] which is this self-same script filename */
       if ( system.args[i].indexOf('--debug')    == 0 ) { debug     = true; /* debug && console.log ('DEBUG: '   + system.args[i]); */ }
  else if ( system.args[i].indexOf('--full_page')== 0 ) { full_page = true; debug && console.log ('PAGE: '    + system.args[i]); }
  else if ( system.args[i].indexOf('--header')   == 0 ) { header_key=system.args[++i]; header_val=system.args[++i] }
  else if ( system.args[i].indexOf('--xff')      == 0 ) { header_val=system.args[++i] } // kludge assume default header_key
  else if ( system.args[i].indexOf('--verbose')  == 0 ) { verbose   = true; debug && console.log ('VERBOSE: ' + system.args[i]); }
  else if ( system.args[i].indexOf('http')== 0 ) { /* http protocol optional for local files */ }
  else if ( system.args[i].indexOf('.htm') > 0 ) { /* to detect local files */ } // kludge?
  else if ( system.args[i].indexOf('.js') > 0 ) { /* to detect local files */ } // kludge?
  else { console.log('unk. param: '+system.args[i]); }
}

page.customHeaders = { header_key : header_val };
debug && console.log ('VERBOSE: ' + header_key +': '+ header_val);

page.onConsoleMessage = function (msg) { // call-back function intercepts console.log messages
    debug && console.log('DEBUG: console.log message="' + msg + '"');
};

page.onLoadFinished = function(status) {
  if ( debug ) {
    // console.log('Status: ' + status +' after onLoadFinished(' + status +')');
    system.stderr.write('Status: ' + (theStatusCode ? theStatusCode : status) +' after onLoadFinished(' + status +')\n');
  }
};

page.onResourceReceived = function(resource) {
  // if (resource.url == URLarg || (theStatusCode >= 300 && theStatusCode < 400)) {
    theStatusPrev = theStatusCode  ;
    theStatusCode = resource.status;
    thePrevURL    = theCurrURL  ;
    theCurrURL    = resource.url;
  // }
    if ( resource.status === 200 ) {
        verbose && console.log('VERBOSE status ' + resource.status + ' for ' + resource.url ); // don't usually log standard success
    } else {
        verbose && console.log('Status Code was: ' + theStatusPrev   + ' for ' + thePrevURL );
        verbose && console.log('Status Code is : ' + theStatusCode   + ' for ' + theCurrURL );
    }
};

page.onUrlChanged = function (URLnew) { // call-back function intercepts console.log messages
    if ( URLnew === URLarg ) {
      debug && console.log('DEBUG: old/new URL: ' + URLnew + ' --onUrlChanged()');
    } else {
      verbose && console.log('DEBUG: old URL: ' + URLarg);
      verbose && console.log('DEBUG: new URL: ' + URLnew);
    }
};

phantom.onError = function(msg, trace) {
    var msgStack = ['PHANTOM ERROR: ' + msg];
    if (trace) {
        msgStack.push('TRACE:');
        trace.forEach(function(t) {
            msgStack.push(' -> ' + (t.file || t.sourceURL) + ': ' + t.line + (t.function ? ' (in function ' + t.function + ')' : ''));
        });
    }
    console.error(msgStack.join('\n'));
};

page.open( URLarg, function () {
    // onLoadFinished executes here
    var page_content = page.content;
    var body_innerHTML= page.evaluate( function() {
      return document.body.innerHTML ? document.body.innerHTML : '(empty)' ;
    });
    var title = page.evaluate(function() {return document.title; });

    // page.render( URLdump); // "screenshot"
    verbose && console.log('VERBOSE: Loading time '+ ( Date.now() - timestamp ) +' msec');

    debug && console.log('DEBUG: Page title: ' + ((title==='') ? '(none)':title) );
    debug && console.log('DEBUG: body_innerHTML.length='+ body_innerHTML.length);
    (debug || verbose) && console.log(' '); // empty line
    if ( full_page  || ( ! body_innerHTML ) || body_innerHTML.length < 9 ) {
      console.log( page_content   ); // return all if body is empty
    } else {
      console.log( body_innerHTML );
    }
    setTimeout(function() {
        verbose && console.log('VERBOSE: status ' + theStatusPrev   + ' for ' + thePrevURL + ' (b)');
        verbose && console.log('VERBOSE: status ' + theStatusCode   + ' for ' + theCurrURL + ' (c)');
      }, 1333 ) ; // delay in milliseconds
    phantom.exit( theStatusCode);
  }) ;

}
EOF
touch exists;
phantomjs hulu.js http://hulu.com | tee exists
if grep -q 'Sorry, currently' "exists"; then
   echo "\n\nHulu is unavailable";
else
   echo "\n\nHulu is available";
fi
rm hulu.js exists;
