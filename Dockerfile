FROM jekyll/jekyll:3.8
WORKDIR /srv/jekyll
COPY . .
# install dependences
RUN bundle install
# expose port
EXPOSE 4000
# run jekyll serve by default
CMD ["jekyll", "serve"]
