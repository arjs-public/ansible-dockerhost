import cherrypy
from datetime import datetime

class HelloWorld(object):
    @cherrypy.expose
    def index(self):
        return "%s - Hello world!" % datetime.now()

if __name__ == '__main__':
    cherrypy.config.update({'server.socket_host': '0.0.0.0', 'server.socket_port': 5000})
    cherrypy.quickstart(HelloWorld())
