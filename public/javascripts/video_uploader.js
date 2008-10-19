var GSports = {	
}

GSports.SwfUpload = Class.create({
    initialize: function(upload_url,file_types,file_size_limit,file_types_description,file_upload_limit){
	this.swfu = new SWFUpload({
	    upload_url : upload_url,
	    flash_url: '/plugin_assets/community_engine/images/swf/swfupload_f9.swf',
	    file_size_limit : file_size_limit || '350000000',
	    file_types : file_types || '*.wmv; *.qt',
	    file_types_description : file_types_description || 'Video Files',
	    file_upload_limit : '0 ', // means they can try again if it fails
            file_queue_limit : '1',
            file_queued_handler : this.fileQueued.bind(this),
	    file_queue_error_handler : this.fileQueueError.bind(this),
	    file_dialog_complete_handler : this.fileDialogComplete.bind(this),
  	    file_dialog_start_handler: this.fileDialogStart.bind(this),
	    upload_progress_handler : this.uploadProgress.bind(this),
	    upload_error_handler : this.uploadError.bind(this),
	    upload_success_handler : this.uploadSuccess.bind(this),
	    upload_complete_handler : this.uploadComplete.bind(this),
            //file_browse_handler : this.fileBrowse.bind(this),
	    custom_settings : { 
		progress_target : 'uploadProgressContainer',
                upload_successful : false
	    }, 
	    debug: false
	});
    },
    
    uploadErrors: [],
    
    fileDialogStart : function() {
	var txtFileName = document.getElementById("uploaded_file_path");
	txtFileName.value = "";
	this.swfu.cancelUpload();
    },

    // Called by the queue complete handler to submit the form
    uploadDone : function() {
	try {
            var form = document.getElementById('upload_form');
            form.submit();
	} catch (ex) {
	    alert("Error submitting form : " + ex);
	}
    },

    fileQueueError : function (file, errorCode, message)  {
	try {
	    // Handle this error separately because we don't want to create a FileProgress element for it.
	    switch (errorCode) {
	    case SWFUpload.QUEUE_ERROR.QUEUE_LIMIT_EXCEEDED:
		alert("You have attempted to queue too many files.\n" + (message === 0 ? "You have reached the upload limit." : "You may select " + (message > 1 ? "up to " + message + " files." : "one file.")));
		return;
	    case SWFUpload.QUEUE_ERROR.FILE_EXCEEDS_SIZE_LIMIT:
		alert("The file you selected is too big.");
		this.swfu.debug("Error Code: File too big, File name: " + file.name + ", File size: " + file.size + ", Message: " + message);
		return;
	    case SWFUpload.QUEUE_ERROR.ZERO_BYTE_FILE:
		alert("The file you selected is empty.  Please select another file.");
		this.swfu.debug("Error Code: Zero byte file, File name: " + file.name + ", File size: " + file.size + ", Message: " + message);
		return;
	    case SWFUpload.QUEUE_ERROR.INVALID_FILETYPE:
		alert("The file you choose is not an allowed file type.");
		this.swfu.debug("Error Code: Invalid File Type, File name: " + file.name + ", File size: " + file.size + ", Message: " + message);
		return;
	    default:
		alert("An error occurred in the upload. Try again later.");
		this.swfu.debug("Error Code: " + errorCode + ", File name: " + file.name + ", File size: " + file.size + ", Message: " + message);
		return;
	    }
	} catch (e) {
	}
    },

    fileQueued : function(file) {
	try {
	    var txtFileName = document.getElementById("uploaded_file_path");
	    txtFileName.value = file.name;
	} catch (e) {
            alert("File queued handler problem : " + e);
	}

    },
    
    fileDialogComplete : function(numFilesSelected, numFilesQueued) {
	//validateForm();
    },

    uploadProgress : function(file, bytesLoaded, bytesTotal) {
	try {
	    var percent = Math.ceil((bytesLoaded / bytesTotal) * 100);

	    file.id = "singlefile";	// This makes it so FileProgress only makes a single UI element, instead of one for each file
	    var progress = new FileProgress(file, this.swfu.customSettings.progress_target);
	    progress.setProgress(percent);
            if (bytesLoaded == bytesTotal)
            {
  	      progress.setStatus("Wrapping up...");
              progress.toggleCancel(false);
              //alert("Set timeout 60 sec on upload success");
              setTimeout(function() {n
                if (document.getElementById("hidFileID").value == "-2")
                {
                  // alert("Forced form submit cancelled");
                  return;
                }
		document.getElementById("hidFileID").value = "-1";
                var form = document.getElementById('upload_form');
                form.submit();
              },60000);
            }
            else
            {
  	      progress.setStatus("Uploading (" + percent + "%) ...");
            }
	} catch (e) {
          //alert("Problem in uploadProgress: " + e);
	}
    },

    uploadSuccess : function(file, serverData) {
	try {
	    file.id = "singlefile";	// This makes it so FileProgress only makes a single UI element, instead of one for each file
	    var progress = new FileProgress(file, this.swfu.customSettings.progress_target);

	    progress.setComplete();
	    progress.setStatus("Complete.");
	    progress.toggleCancel(false);

	    if (serverData === " " || serverData.indexOf("Error") > -1) {
		this.swfu.customSettings.upload_successful = false;
	    } else {
		this.swfu.customSettings.upload_successful = true;
		document.getElementById("hidFileID").value = serverData;
	    }
	    
	} catch (e) {
            alert("uploadsuccess handler problem : " + e);
	}
    },

    uploadComplete : function(file) {
	try {
	    if (this.swfu.customSettings.upload_successful) {
		document.getElementById("btnBrowse").disabled = "true";
		this.uploadDone();
	    } else {
		file.id = "singlefile";	// This makes it so FileProgress only makes a single UI element, instead of one for each file
		var progress = new FileProgress(file, this.swfu.customSettings.progress_target);
		progress.setError();
		progress.setStatus("File rejected");
		progress.toggleCancel(false);
		
		var txtFileName = document.getElementById("uploaded_file_path");
		txtFileName.value = "";
                // This will cancel any pending forced form submit
		document.getElementById("hidFileID").value = "-2";
		validateForm();

		alert("There was a problem with the upload.\nThe server did not accept it.");
	    }
	} catch (e) {
            alert("Problem in uploadComplete : " + e);
	}
    },

    uploadError : function(file, errorCode, message) {
	try {
	    var txtFileName = document.getElementById("uploaded_file_path");
	    txtFileName.value = "";
	    
	    // Handle this error separately because we don't want to create a FileProgress element for it.
	    switch (errorCode) {
	    case SWFUpload.UPLOAD_ERROR.MISSING_UPLOAD_URL:
		alert("There was a configuration error.  You will not be able to upload a resume at this time.");
		this.swfu.debug("Error Code: No backend file, File name: " + file.name + ", Message: " + message);
		return;
	    case SWFUpload.UPLOAD_ERROR.UPLOAD_LIMIT_EXCEEDED:
		alert("You may only upload 1 file.");
		this.swfu.debug("Error Code: Upload Limit Exceeded, File name: " + file.name + ", File size: " + file.size + ", Message: " + message);
		return;
	    case SWFUpload.UPLOAD_ERROR.FILE_CANCELLED:
	    case SWFUpload.UPLOAD_ERROR.UPLOAD_STOPPED:
		break;
	    default:
		alert("An error occurred in the upload. Try again later.");
		this.swfu.debug("Error Code: " + errorCode + ", File name: " + file.name + ", File size: " + file.size + ", Message: " + message);
		return;
	    }

	    file.id = "singlefile";	// This makes it so FileProgress only makes a single UI element, instead of one for each file
	    var progress = new FileProgress(file, this.swfu.customSettings.progress_target);
	    progress.setError();
	    progress.toggleCancel(false);

	    switch (errorCode) {
	    case SWFUpload.UPLOAD_ERROR.HTTP_ERROR:
		progress.setStatus("Upload Error");
		this.swfu.debug("Error Code: HTTP Error, File name: " + file.name + ", Message: " + message);
		break;
	    case SWFUpload.UPLOAD_ERROR.UPLOAD_FAILED:
		progress.setStatus("Upload Failed.");
		this.swfu.debug("Error Code: Upload Failed, File name: " + file.name + ", File size: " + file.size + ", Message: " + message);
		break;
	    case SWFUpload.UPLOAD_ERROR.IO_ERROR:
		progress.setStatus("Server (IO) Error");
		this.swfu.debug("Error Code: IO Error, File name: " + file.name + ", Message: " + message);
		break;
	    case SWFUpload.UPLOAD_ERROR.SECURITY_ERROR:
		progress.setStatus("Security Error");
		this.swfu.debug("Error Code: Security Error, File name: " + file.name + ", Message: " + message);
		break;
	    case SWFUpload.UPLOAD_ERROR.FILE_CANCELLED:
		progress.setStatus("Upload Cancelled");
		this.swfu.debug("Error Code: Upload Cancelled, File name: " + file.name + ", Message: " + message);
		break;
	    case SWFUpload.UPLOAD_ERROR.UPLOAD_STOPPED:
		progress.setStatus("Upload Stopped");
		this.swfu.debug("Error Code: Upload Stopped, File name: " + file.name + ", Message: " + message);
		break;
	    }
	} catch (ex) {
	}
    }

});

function FileProgress(file, targetID) {
    this.fileProgressID = file.id;

    this.opacity = 100;
    this.height = 0;

    this.fileProgressWrapper = document.getElementById(this.fileProgressID);
    if (!this.fileProgressWrapper) {
	this.fileProgressWrapper = document.createElement("div");
	this.fileProgressWrapper.className = "progressWrapper";
	this.fileProgressWrapper.id = this.fileProgressID;

	this.fileProgressElement = document.createElement("div");
	this.fileProgressElement.className = "progressContainer";

	var progressCancel = document.createElement("a");
	progressCancel.className = "progressCancel";
	progressCancel.href = "#";
	progressCancel.style.visibility = "hidden";
	progressCancel.appendChild(document.createTextNode(" "));

	var progressText = document.createElement("div");
	progressText.className = "progressName";
	progressText.appendChild(document.createTextNode(file.name));

	var progressBar = document.createElement("div");
	progressBar.className = "progressBarInProgress";

	var progressStatus = document.createElement("div");
	progressStatus.className = "progressBarStatus";
	progressStatus.innerHTML = "&nbsp;";

	this.fileProgressElement.appendChild(progressCancel);
	this.fileProgressElement.appendChild(progressText);
	this.fileProgressElement.appendChild(progressStatus);
	this.fileProgressElement.appendChild(progressBar);

	this.fileProgressWrapper.appendChild(this.fileProgressElement);

	document.getElementById(targetID).appendChild(this.fileProgressWrapper);
    } else {
	this.fileProgressElement = this.fileProgressWrapper.firstChild;
    }

    this.height = this.fileProgressWrapper.offsetHeight;

}
FileProgress.prototype.setProgress = function (percentage) {
    this.fileProgressElement.className = "progressContainer green";
    this.fileProgressElement.childNodes[3].className = "progressBarInProgress";
    this.fileProgressElement.childNodes[3].style.width = percentage + "%";
};
FileProgress.prototype.setComplete = function () {
    this.fileProgressElement.className = "progressContainer blue";
    this.fileProgressElement.childNodes[3].className = "progressBarComplete";
    this.fileProgressElement.childNodes[3].style.width = "";

    var oSelf = this;
    setTimeout(function () {
	oSelf.disappear();
    }, 10000);
};
FileProgress.prototype.setError = function () {
    this.fileProgressElement.className = "progressContainer red";
    this.fileProgressElement.childNodes[3].className = "progressBarError";
    this.fileProgressElement.childNodes[3].style.width = "";

    var oSelf = this;
    setTimeout(function () {
	oSelf.disappear();
    }, 5000);
};
FileProgress.prototype.setCancelled = function () {
    this.fileProgressElement.className = "progressContainer";
    this.fileProgressElement.childNodes[3].className = "progressBarError";
    this.fileProgressElement.childNodes[3].style.width = "";

    var oSelf = this;
    setTimeout(function () {
	oSelf.disappear();
    }, 2000);
};
FileProgress.prototype.setStatus = function (status) {
    this.fileProgressElement.childNodes[2].innerHTML = status;
};

// Show/Hide the cancel button
FileProgress.prototype.toggleCancel = function (show, swfUploadInstance) {
    this.fileProgressElement.childNodes[0].style.visibility = show ? "visible" : "hidden";
    if (swfUploadInstance) {
	var fileID = this.fileProgressID;
	this.fileProgressElement.childNodes[0].onclick = function () {
	    swfUploadInstance.cancelUpload(fileID);
	    return false;
	};
    }
};

// Fades out and clips away the FileProgress box.
FileProgress.prototype.disappear = function () {

    var reduceOpacityBy = 15;
    var reduceHeightBy = 4;
    var rate = 30;	// 15 fps

    if (this.opacity > 0) {
	this.opacity -= reduceOpacityBy;
	if (this.opacity < 0) {
	    this.opacity = 0;
	}

	if (this.fileProgressWrapper.filters) {
	    try {
		this.fileProgressWrapper.filters.item("DXImageTransform.Microsoft.Alpha").opacity = this.opacity;
	    } catch (e) {
		// If it is not set initially, the browser will throw an error.  This will set it if it is not set yet.
		this.fileProgressWrapper.style.filter = "progid:DXImageTransform.Microsoft.Alpha(opacity=" + this.opacity + ")";
	    }
	} else {
	    this.fileProgressWrapper.style.opacity = this.opacity / 100;
	}
    }

    if (this.height > 0) {
	this.height -= reduceHeightBy;
	if (this.height < 0) {
	    this.height = 0;
	}

	this.fileProgressWrapper.style.height = this.height + "px";
    }

    if (this.height > 0 || this.opacity > 0) {
	var oSelf = this;
	setTimeout(function () {
	    oSelf.disappear();
	}, rate);
    } else {
	this.fileProgressWrapper.style.display = "none";
    }
};

// Called by the submit button to start the upload
function doSubmit(e) {
    e = e || window.event;
    if (e && e.stopPropagation) e.stopPropagation();
    else if (e && e.cancelBubble) e.cancelBubble = true;
    if (e && e.preventdefault) e.preventDefault(); 
    else if (e && e.returnValue) e.returnValue = false;
    try {
	uploader.swfu.startUpload();
    } catch (ex) {
        alert("could not start uploader " + ex);
    }
    return false;
}

function validateForm() {
}
