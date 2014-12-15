var gulp = require('gulp');
var shell = require('gulp-shell');

function swallowError (error) {
  //If you want details of the error in the console
  // console.log(error.toString());
  this.emit('end');
}

gulp.task('test', function () {
  return gulp.src('test/server-test.js', {read: false})
    .pipe(shell('tape <%= file.path %>'), {ignoreErrors: true})
    .on('error', swallowError)
})

gulp.task('default', ['test'], function() {
  gulp.watch(['lib/**/*.js', 'test/**/*.js'], ['test'])
});

gulp.task('js', shell.task([
  'watchify ./js/client-image/browser.js -o ./public/client-image.js -d'
]));

gulp.task('index', shell.task([
  'watchify ./js/index.js -o ./public/index.js -d'
]));