#Author: https://github.com/cottinghamd
#This script will backup solution articles from a FreshDesk instance using the v2 API

$apikey = Read-Host "Please Enter Your Freshdesk API Key"
$apikey = "$apikey" + ":x"
$Bytes = [System.Text.Encoding]::Unicode.GetBytes($apikey)
$apikey =[Convert]::ToBase64String($Bytes)

$outputfolder = Read-Host "Please type the folder path you want to export articles to, for example c:\output\ (the last part of the path must be enclosed)"

$ratelimit = Read-Host "Do you want to rate limit your requests which may be needed for some FreskDesk plans? (y/n)"

function RateLimit
{
    if ($ratelimit -eq "y")
    {
        Start-Sleep -Seconds 3
    }
}

$hdrs = @{}
$hdrs.Add("Authorization","Basic $apikey")

#Request the categories from FreshDesk
$categories = Invoke-RestMethod -Uri https://airlockdigital.freshdesk.com/api/v2/solutions/categories -Method Get -ContentType 'application/json' -Headers $hdrs

Write-Host "There are" $categories.Count "Solution Categories in FreshDesk" -ForegroundColor Cyan

#Commence iterating through each freshdesk category
foreach ($category in $categories)
{
    Write-Host "Traversing the" $category.name "Category"
    $categoryid = $category.id

    #Request the folders within the current category from FreshDesk
    $folders = Invoke-RestMethod -Uri https://airlockdigital.freshdesk.com/api/v2/solutions/categories/$categoryid/folders -Method Get -ContentType 'application/json' -Headers $hdrs

    Write-Host "There are" $folders.count "folders within the" $category.name "category" -ForegroundColor Yellow

    #Sanitise the current category name to ensure all characters are file system friendly
    $categoryname = $category.name -replace '(-|#|\||"|,|/|:|â|€|™|\?)', ''

    #Create a new directory in the output path with the category name
    New-Item -Path "$outputfolder" -Name $categoryname -ItemType "directory" | Out-Null

    $currentfolder = $outputfolder + $categoryname

    #Commence iterating through each folder to determine how many articles are in it
    foreach ($folder in $folders)
    {

        #Select the current folder id and request the folder contents from FreshDesk
        $folderid = $folder.id
        $articles = Invoke-RestMethod -Uri https://airlockdigital.freshdesk.com/api/v2/solutions/folders/$folderid/articles -Method Get -ContentType 'application/json' -Headers $hdrs

        Write-Host "There are" $articles.count "articles within the" $folder.name "folder" -ForegroundColor Green

        #Sanitise the current folder name to ensure all characters are file system friendly
        $foldername = $folder.name -replace '(-|#|\||"|,|/|:|â|€|™|\?)', ''

        #Create a new folder in the output path with the folder name
        New-Item -Path $currentfolder -Name $foldername -ItemType "directory" | Out-Null

        $finalfolder = $currentfolder + "\" + $foldername

        Write-Host "The export folder is" $finalfolder -ForegroundColor Magenta

        #Commence iterating through the articles and pull out the HTML content for each
        foreach ($article in $articles)
        {
            RateLimit

            Write-Host "       Exporting" $article.Title

            #Sanitise the current article name to ensure all characters are file system friendly
            $articletitle = $article.Title -replace '(-|#|\||"|,|/|:|â|€|™|\?)', ''

            $outputpath = $finalfolder + "\" + $articletitle + ".html"

            $outputpath = $outputpath -replace ' \\','\\'

            #Write the article to disk
            $article.description | Out-File -FilePath $outputpath

            $totalarticles++
        }

    }

}

Write-Host $totalarticles "solution articles exported" -ForegroundColor Gray
