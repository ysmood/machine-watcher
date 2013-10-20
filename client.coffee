net = require 'net'
os = require 'os'

conf = require './config'

get_data_pack = ->
	mem_unit = 1024 * 1024
	data = {
		key: conf.key
		name: conf.name
		hostname: os.hostname()
		os: os.type() + ', ' + os.release()
		uptime: parseInt(os.uptime() / 60 / 60) + ' hours'
		mem: parseInt(os.freemem() / mem_unit) + ' MB / ' +
			 parseInt(os.totalmem() / mem_unit) + ' MB'
	}

	return JSON.stringify(data)

curl = (xurl, done) ->

	c = net.connect(xurl, ->
		c.write(xurl.req_data)
	)

	c.on('data', (data) ->
		xurl.res_data = data.toString()
		done(xurl)

		c.end()
	)

	c.setTimeout(conf.socket_timeout)

report = ->
	xurl = {
		host: conf.server_host
		port: conf.port
	}
	xurl.req_data = get_data_pack()

	curl(xurl, (xurl) ->
		console.log xurl.res_data
	)

report()

# Unit minute
setInterval(report, conf.report_span * 1000 * 60)
