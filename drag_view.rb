# Usage:
# drag_view = NSDragView.create(options)
# options:
#   :frame [Array] - as for any view
#   :acceptableTypes [Array] - extensions of accepted files
#   :acceptFolders [Boolean] - should folders be allowed?
# methods:
#   acceptableTypes=[Array] - as in options
#   acceptFolders=[Boolean] - as in options
# callbacks
#   onFile(filePath) - called for each file that was dragged(single file per call)
#   onFiles(filePaths) - called for all files that was dragged(all files in one call)

class NSDragView < NSView
  include HotCocoa::Behaviors

  attr_accessor :acceptableTypes, :acceptFolders

  def self.create(options)
    instance = alloc
    instance.initWithFrame options.delete(:frame)
    instance.acceptableTypes = options.delete(:acceptableTypes) || []
    instance.acceptFolders = !!options.delete(:acceptFolders)
    instance
  end

  def initWithFrame(frame)
    if super
      registerForDraggedTypes([NSFilenamesPboardType])
      @acceptableTypes = []
      self.layout = {}
      self
    end
  end

  def draggingEntered(sender)
    pboard = sender.draggingPasteboard
    sourceDragMask = sender.draggingSourceOperationMask
    canInitDraggedFiles = false

    if pboard.types.containsObject(NSFilenamesPboardType)
      pboard.propertyListForType(NSFilenamesPboardType).each do |filePath|
        if fileAllowed(filePath)
          canInitDraggedFiles = true
          break
        end
      end
      
      if canInitDraggedFiles and (sourceDragMask & NSDragOperationCopy)
        return NSDragOperationCopy
      end
    end
    return NSDragOperationNone
  end

  def performDragOperation(sender)
    filePaths = []
    pboard = sender.draggingPasteboard
    if pboard.types.containsObject(NSFilenamesPboardType)
      pboard.propertyListForType(NSFilenamesPboardType).each do |filePath|
        if fileAllowed(filePath)
          filePaths << filePath
          callOnFile(filePath)
        end
      end
      callOnFiles(filePaths) unless filePaths.empty?
      return true
    end
    return false
  end
  
  def onFile(&block)
    @onFile = block
  end
  
  def onFiles(&block)
    @onFiles = block
  end
  
  private
  
  def callOnFile(filePath)
    @onFile.yield(filePath) if @onFile
  end
  
  def callOnFiles(filePaths)
    @onFiles.yield(filePaths) if @onFiles
  end
  
  def filemanager; @filemanager ||= NSFileManager.defaultManager; end
  def workspace; @workspace ||= NSWorkspace.sharedWorkspace; end
  
  def fileAllowed(filePath)
    if @acceptFolders
      ptr = Pointer.new_with_type('B')
      filemanager.fileExistsAtPath(filePath, isDirectory: ptr)
      pathIsDirectory = ptr[0]
      return true if pathIsDirectory
    end
    
    return true if @acceptableTypes.containsObject(filePath.pathExtension)
    return false
  end  
end
