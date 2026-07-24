# How to upload asset files

Right now, only .png files are being tracked by git lfs

If you find an asset you want to upload that has a different extension
than .png, add them to git-lfs with the following command:

`$ git lfs track "*.<file extension>"`

for example, when I started the project I ran

`$ git lfs track "*.png"`

This command only needs to be run once per file extension used. It updates
the .gitattributes file in the project root, so doing this tracks the files
for both of us.

To add specific files, you need to manually add them through git like you
would a normal file:

`$ git add -f <path/to/asset/file`

The -f is there because by default, the asssets directory is ignored by
git (I thought this was easier and makes us only upload assets we specifically
want to upload rather than uploading junk we're not using).

You can add entire directories using the * operator as well:

`$ git add -f assets/example_directory/*`

After adding the files, you commit and push like a normal git workflow:

`$ git commit -m "<message>"`

`$ git push -u origin main`

Note that you can edit/add normal files and asset files in the same commit,
but you have to add the asset files specifically since they are ignored by
default. Running

`$ git add .`

will not add any asset files.
