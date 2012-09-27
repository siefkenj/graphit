<?php
	/* 
	 * Script to take post data and return the data with an
	 * appropriate with an appropriate header so a users is prompted
	 * for a download
	 */

        $filename = $_POST['filename'];
        $file_contents = $_POST['data'];
        $mimetype = "application/octet-stream";
        if (in_array('mimetype', $_POST)) {
                $mimetype = $_POST['mimetype'];
        }

        // Set headers
        header("Cache-Control: public");
        header("Content-Description: File Transfer");
        header("Content-Disposition: attachment; filename=$filename");
        header("Content-Type: " . $mimetype);
        header("Content-Transfer-Encoding: binary");

        echo base64_decode($file_contents);
?> 

