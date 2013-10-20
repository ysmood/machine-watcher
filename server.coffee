net = require 'net'
fs = require 'fs'
nodemailer = require 'nodemailer'

conf = require './config'

machines = {}

init_machines = ->
	for key in conf.accept_keys
		machines[key] = {
			last_report: Date.now()
			last_mail: Date.now()
			data: null
		}

send_mail_report = (info) ->
	span = (Date.now() - info.last_mail) / 1000 / 60 / 60
	if span < conf.mail_span
		return

	mailer = nodemailer.createTransport("SMTP", conf.smtp)

	mail = {
		from: 'machine-watcher@ysmood.org'
		to: conf.mail_to
		subject: 'Machine Report'
		html: '<h3>Remote machien is down.</h3>' +
			'<pre>' + JSON.stringify(info.data, null, 4) + '</pre>'
	}

	mailer.sendMail(mail, (err, res) ->
		if err
			console.log(err)
		else
			console.log("Message sent: " + res.message)

		mailer.close()
		info.last_mail = Date.now()
	)

log = (data) ->
	fs.appendFile(conf.log_file, JSON.stringify(data) + '\n')

watcher = ->
	for k, info of machines
		span = (Date.now() - info.last_report) / 1000 / 60
		if span > conf.report_span * 2
			send_mail_report(info)
			console.log 'miss'

launch_server = ->
	init_machines()

	srv = net.createServer((c) ->
		c.setTimeout(conf.socket_timeout)

		c.on('data', (data) ->
			try
				data = JSON.parse(data.toString())
			catch e
				c.end('auth error')
				return

			if not machines.hasOwnProperty(data.key)
				c.end('auth error')
				return

			machines[data.key] = {
				last_report: Date.now()
				last_mail: Date.now()
				data: data
			}

			log data
			c.end('server ok')
		)
	)


	srv.listen(conf.port, ->
		console.log "Start at " + conf.port
	)

	setInterval(watcher, conf.report_span * 1000 * 60)

launch_server()