{createServer} = require 'http'

{parse} = require 'url'

{resolveCname} = require 'dns'

{ns, start, end} = require './ns.json'


cache = {}

query = (i, n) ->
	subdomain = n + '-' + ns + i
	console.log subdomain
	domain = subdomain + '.rhcloud.com'
	resolveCname domain, (err, cname) ->
		return if err?
		resolveCname cname[0], (err, ec2_cname) ->
			return if err?
			cache[subdomain] = ec2_cname[0]


queryAll = ->
	[start..end].forEach (i) ->
		[1..3].forEach (n) ->
			query i, n

cron_job = ->
	queryAll()
	setTimeout cron_job, 30 * 1000

cron_job()

server = createServer (req, res) ->
	{query: {q}} = parse req.url, true
	if q? and (cname = cache[q])?
		res.end JSON.stringify cname
	else
		res.end JSON.stringify cache

{OPENSHIFT_NODEJS_PORT: PORT, OPENSHIFT_NODEJS_IP: IP} = process.env

server.listen PORT or 3000, IP or '127.0.0.1'