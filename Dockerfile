FROM ubuntu

ARG BUILDKITE_TOKEN

#Update and Install base dependencies
RUN apt-get update -qq && apt-get install -y \
apt-transport-https \
openssh-client \
curl \
zip \
wget \
expect \
openjdk-8-jdk \
libc6-i386 \ 
lib32stdc++6 \
lib32gcc1 \ 
lib32ncurses5 \
lib32z1

#Add Buildkite configuration files
ADD buildkite-agent.cfg /etc/buildkite-agent/buildkite-agent.cfg
RUN sed -i -- "s/BUILDKITE_TOKEN/$BUILDKITE_TOKEN/" /etc/buildkite-agent/buildkite-agent.cfg
ADD hooks /etc/buildkite-agent/hooks

#Add Signed Buildkite repository
RUN sh -c 'echo deb https://apt.buildkite.com/buildkite-agent stable main > /etc/apt/sources.list.d/buildkite-agent.list'
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 32A37959C2FA5C3C99EFBC32A79206696452D198

#Install buildkite agent
RUN apt-get update && apt-get install -y buildkite-agent

#Install buildkite bootstrap
RUN curl -Lfs -o /etc/buildkite-agent/bootstrap.sh \
https://raw.githubusercontent.com/buildkite/agent/2-1-stable/templates/bootstrap.sh \
&& chmod +x /etc/buildkite-agent/bootstrap.sh

#Setup the buildkite builds folder
RUN mkdir -p /var/lib/buildkite-agent/builds

#SSH Key Setup
RUN mkdir -p ~/.ssh

#Install Android
RUN wget --quiet --output-document=sdkmanager.zip https://dl.google.com/android/repository/sdk-tools-linux-3859397.zip
RUN unzip sdkmanager.zip -d /etc/android-sdk
RUN rm /sdkmanager.zip

#Install Android SDK and Tooling
ENV ANDROID_HOME=/etc/android-sdk
RUN mkdir -p ~/.android && touch ~/.android/repositories.cfg
RUN /etc/android-sdk/tools/bin/sdkmanager \
"build-tools;25.0.3" \
"build-tools;26.0.1" \
"extras;android;m2repository" \
"extras;google;m2repository" \
"ndk-bundle" \
"platform-tools" \
"platforms;android-25" \
"platforms;android-26"
RUN yes | /etc/android-sdk/tools/bin/sdkmanager --licenses

#Start build kite agent
CMD buildkite-agent start --bootstrap-script=/etc/buildkite-agent/bootstrap.sh --build-path=/var/lib/buildkite-agent/builds --hooks-path=/etc/buildkite-agent/hooks