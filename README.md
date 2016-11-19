# merge-dream
## Install dependencies
```
gem install optparse
gem install mechanize
gem install rest-client
gem install activesupport -v "=4.1.2"
```
## Set up environment variables
```
export SOMATIC_API_KEY='your somatic_api_key pasted here'
export SOMATIC_ORG_API_KEY='your somatic_api_key pasted here'
export SOMATIC_ENV=production
```
## Usage
```
ruby merge_inception.rb -f "full path of image"  -c class1,class2
```
class1 and class2 can be chosen from 0-16, for example:
```
ruby merge_inception.rb -f "full path of image"  -c 0,8
ruby merge_inception.rb -f "full path of image"  -c 4,11
```
