urac =
  uploads : 0
  webm : cnt : 0, rec : [], up : [], o : "ogg"
  ogg  : cnt : 0, rec : [], up : [], o : "webm"
  width : 320
  height : 240
  init : ->
    urac.container = document.getElementById "videos-container"
    urac.start = document.querySelector "#play"
    urac.stop = document.querySelector "#stop"
    urac.start.disabled = false
    navigator.getUserMedia {audio:true,video:true}, urac.gotAccess, (e) ->
      console.error "media error", e
      true
    true
  gotAccess : (stream) ->
    urac.start.onclick = ->
      urac.webm.cnt = 0
      urac.ogg.cnt = 0
      urac.video.start 5000
      urac.audio.start 5000
      @disabled = true
      urac.stop.disabled = no
      true
    urac.stop.onclick = ->
      @disabled = yes
      urac.start.disabled = no
      urac.video.stop()
      urac.audio.stop()
      urac.stopped = true
      true
    urac.player = document.createElement("video")
    urac.player = mergeProps urac.player,
      controls: true
      width: urac.width
      height: urac.height
      src: URL.createObjectURL(stream)
    urac.player.play()
    urac.container.appendChild urac.player
    urac.video = new MediaStreamRecorder(stream)
    urac.video.mimeType = "video/webm"
    urac.video.videoWidth = urac.width
    urac.video.videoHeight = urac.height
    urac.audio = new MediaStreamRecorder(stream)
    urac.audio.mimeType = 'audio/ogg'
    urac.audio.ondataavailable = (blob) -> gotChunk "ogg", blob
    urac.video.ondataavailable = (blob) -> gotChunk "webm", blob
    true
gotChunk = (format,blob) ->
  urac.uploads++
  idx = urac[format].cnt
  url = "/urac/" + idx + "." + format
  xhr = new XMLHttpRequest()
  commitDone = (e) ->
    console.log "Done ", idx, urac.uploads
    if urac.stopped and urac.uploads is 0
      urac.stopped = no
      $.get("/urac?action=cut&idx="+(urac.webm.cnt-1)).success commitDone
  uploadDone = ->
    if xhr.readyState is 4 and xhr.status is 200
      console.log 'upld', format, idx
      urac.uploads--
      urac[format].up[idx] = true
      if urac[urac[format].o].up[idx] is true
        $.get("/urac?action=commit&idx="+idx).success commitDone
  xhr.open "PUT", url, true
  xhr.onreadystatechange = uploadDone
  xhr.send blob
  urac[format].cnt++
$ urac.init
