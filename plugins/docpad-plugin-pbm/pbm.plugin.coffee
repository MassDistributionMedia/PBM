# Export
module.exports = (BasePlugin) ->
	# Define
	class pbmPlugin extends BasePlugin
		# Name
		name: 'pbm'

		# Config
		config:
			collectionName: 'timelines'
			relativeDirPath: 'timelines'
			postUrl: '/timeline'
			extension: '.html'
			blockHtml: """
				<section class="timelines">

					<div class="timelines-new">
						<h2>New Timeline</h2>

						<form action="/timeline" method="POST">
							<input type="hidden" name="for" value="<%= @document.relativeBase %>" />
							<label>Title: <input type="text" name="title" /></label>
							<label>json: <input type="text" name="title" /></label>
							<input class="pure-button" type="submit" value="Create Timeline" />
						</form>
					</div>

					<div class="timelines-list">
						<h2>timelines</h2>
						<% if @getTimelines().length is 0: %>
							<p>No timelines yet</p>
						<% else: %>
							<ul>
								<% for timeline in @getTimelines().toJSON(): %>
									<li>
										<a href="<%=timeline.url%>"><%=timeline.title or timeline.contentRenderedWithoutLayouts%></a>
									</li>
								<% end %>
							</ul>
						<% end %>
					</div>

				</section>
				""".replace(/^\s+|\n\s*|\s+$/g,'')

		# Extend Template Data
		# Add our form to our template data
		extendTemplateData: ({templateData}) ->
			# Prepare
			plugin = @
			docpad = @docpad

			# getTimelinesBlock
			templateData.getTimelinesBlock = ->
				@referencesOthers()
				return plugin.getConfig().blockHtml

			# getTimelines
			templateData.getTimelines = ->
				return docpad.getCollection(plugin.getConfig().collectionName).findAll(for: @document.relativeBase)

			# Chain
			@


		# Extend Collections
		# Create our live collection for our timelines
		extendCollections: ->
			# Prepare
			config = @getConfig()
			docpad = @docpad
			database = docpad.getDatabase()

			# Create the collection
			timelines = database.findAllLive({relativeDirPath: $startsWith: config.relativeDirPath}, [date:-1])

			# Set the collection
			docpad.setCollection(config.collectionName, timelines)

			# Chain
			@


		# Server Extend
		# Add our handling for posting the timeline
		serverExtend: (opts) ->
			# Prepare
			{server} = opts
			plugin = @
			docpad = @docpad
			database = docpad.getDatabase()

			# timeline Handing
			server.all @getConfig().postUrl, (req,res,next) ->
				# Prepare
				config = plugin.getConfig()
				now = new Date(req.body.date or null)
				nowTime = now.getTime()
				nowString = now.toString()
				redirect = req.body.redirect ? req.query.redirect ? 'back'

				# Create Story function to create new timeline
				createStoryJS
					type: "timeline"
					width: "800"
					height: "600"
					source: "scripts/example_json.json"
					embed_id: "PBM-homepage-timeline"

				# Prepare
				documentAttributes =
					data: '<div id="PBM-homepage-timeline"> </div>' or ''
					meta:
						title: req.body.title or "timeline at #{nowString}"
						for: req.body.for or ''
						author: req.body.author or ''
						date: now
						fullPath: docpad.config.documentsPaths[0]+"/#{config.relativeDirPath}/#{nowTime}#{config.extension}"

				# Create document from attributes
				document = docpad.createDocument(documentAttributes)

				# Inject helper
				config.injectDocumentHelper?.call(me, document)

				# Add it to the database
				database.add(document)

				# Listen for regeneration
				docpad.once 'generateAfter', ->
					# Check
					# return next(err)  if err

					# Update browser
					if redirect is 'back'
						res.redirect('back')
					else if redirect is 'document'
						res.redirect(document.get('url'))
					else
						res.json(documentAttributes)

					# No need to call next here as res.send/redirect will do it for us

				# Write source which will trigger the regeneration
				document.writeSource {cleanAttributes:true}, (err) ->
					# Check
					return next(err)  if err

			# Done
			@
