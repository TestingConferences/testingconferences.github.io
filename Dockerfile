FROM jekyll/jekyll:3.8
WORKDIR /srv/jekyll
COPY . .
# install dependence
RUN bundle install
# expose port
EXPOSE 4000
# run jekyll serve defaultly
CMD ["jekyll", "serve"]
