
#!/usr/bin/env python
import os, sys
from app import create_app
from flask_script import Manager, Shell

# Create app
app = create_app()

# Setup a shell interface to run/test it
def make_shell_context():
    return dict(app=app)
manager = Manager(app)
manager.add_command("shell", Shell(make_context=make_shell_context))

@manager.command
def develop():
    app.run(host='127.0.0.1')

@manager.command
def test(coverage=False):
    """Run the unit tests."""
    import sys, unittest
    if coverage and not os.environ.get('FLASK_COVERAGE'):
        os.environ['FLASK_COVERAGE'] = '1'
        os.execvp(sys.executable, [sys.executable] + sys.argv)
    tests = unittest.TestLoader().discover('tests')
    results = unittest.TextTestRunner(verbosity=2).run(tests)
    if (len(results.errors) > 0 or
        len(results.failures) > 0):
        print('Tests failed:')
        sys.exit(1)

@manager.command
def profile(length=25, profile_dir=None):
    """Start the application under the code profiler."""
    from werkzeug.contrib.profiler import ProfilerMiddleware
    app.wsgi_app = ProfilerMiddleware(app.wsgi_app, restrictions=[length],
                                      profile_dir=profile_dir)
    app.run()


if __name__ == '__main__':
    manager.run()