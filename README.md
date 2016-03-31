# confluence-vim

A vim plugin for taking notes in markdown and storing them in a confluence wiki.
This is the extended version of the confluence-vim plugin provided by alawibaba

## Installation

The follwing dependencies need to be satisfied to use the plugin

* html2text
* markdown
* requests

furthermore vim needs to be compiled with python support.

The confluence credentials used to access the wiki need to reside in
the .netrc file in your homedirectory and should look like

machine confluence.<YOURDOMAIN>
login <USERNAME>
password <PASSWORD>

the url of the confluence instance itself should be added to your .vimrc file like

let g:confluence_url= 'https://confluence.<YOURDOMAIN>'

Install the extension by copying the plugin to the .vim/plugin folder

## Usage

To open a new or existing page simply call
vi conf://<SPACEKEY>/<PAGE>
if the <PAGE> does not exist than a new one will be created otherwise
the existing content will be loaded

An overview of the available markup tags in confluence can be found at
https://confluence.atlassian.com/doc/confluence-wiki-markup-251003035.html

## History

## Credits

Thanks to alawibaba for the inital version

## License

see the license file
