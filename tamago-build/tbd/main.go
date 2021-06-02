package main

import (
	"context"
	"fmt"
	"github.com/docker/docker/api/types"
	"github.com/docker/docker/api/types/filters"
	"github.com/docker/docker/api/types/mount"
	"github.com/docker/docker/pkg/jsonmessage"
	"github.com/docker/docker/pkg/stdcopy"
	"github.com/moby/term"
	"io"
	"os"
	"path/filepath"

	"github.com/docker/docker/api/types/container"
	"github.com/docker/docker/client"
)

const (
	// workDir is the path the Dockerfile expects the project to exist at
	workDir = "/workdir"
	// buildDir is the path the Dockerfile will output the built artefacts to
	buildDir = "/workdir/build"
	// tamagoBuildDockerProject is the project name on Docker Hub
	tamagoBuildDockerProject = "f-secure-foundry/tamago-go"
	// containerName is the name of the container to create
	containerName = "tamago-build"
)

func main() {
	if len(os.Args) <= 1 || os.Args[1] == "--help" {
		exitWithUsage()
	}

	pwd, err := os.Getwd()
	if err != nil {
		exitWithError("Couldn't discover current working directory: %v\n", err)
	}

	docker, err := client.NewClientWithOpts(client.FromEnv, client.WithAPIVersionNegotiation())
	if err != nil {
		exitWithError("Couldn't connect to Docker: %n\n", err)
	}

	target := os.Args[1]

	mainPath := "."
	if len(os.Args) >= 4 {
		mainPath = os.Args[3]
	}

	mounts := []mount.Mount{{
		Type:   mount.TypeBind,
		Source: pwd,
		Target: workDir,
	}}

	if len(os.Args) >= 3 {
		outPath := os.Args[2]
		if !dirIsPresent(outPath) {
			exitWithError("Given output directory (%s) isn't present. Do you need to mount your SD card?", outPath)
		}

		mounts = append(mounts, mount.Mount{
			Type:   mount.TypeBind,
			Source: outPath,
			Target: buildDir,
		})
	}

	if err := run(docker, target, mainPath, mounts); err != nil {
		exitWithError("Build failed: %v\n", err)
	}
}

func run(docker *client.Client, target, mainPath string, mounts []mount.Mount) error {
	imageName := tamagoBuildDockerProject + ":" + target
	ctx := context.Background()
	if err := pullImage(docker, ctx, imageName, false); err != nil {
		return err
	}

	config := &container.Config{
		Image: imageName,
		Cmd:   []string{mainPath},
		Tty:   false,
	}
	hostConfig := &container.HostConfig{
		AutoRemove: true,
		Mounts:     mounts,
	}

	c, err := docker.ContainerCreate(ctx, config, hostConfig, nil, nil, containerName+"."+target)
	if err != nil {
		return fmt.Errorf("couldn't create a tamago-build container\n%w", err)
	}

	if err := docker.ContainerStart(ctx, c.ID, types.ContainerStartOptions{}); err != nil {
		return fmt.Errorf("couldn't start the tamago-build container\n%w", err)
	}

	if out, err := docker.ContainerLogs(ctx, c.ID, types.ContainerLogsOptions{ShowStdout: true, ShowStderr: true, Follow: true}); err == nil {
		_, _ = stdcopy.StdCopy(os.Stdout, os.Stderr, out)
	}

	return nil
}

func pullImage(docker *client.Client, ctx context.Context, imageName string, useCache bool) error {
	query := filters.NewArgs()
	query.Add("reference", imageName)

	if useCache {
		cs, err := docker.ImageList(ctx, types.ImageListOptions{Filters: query})
		if err != nil {
			return fmt.Errorf("Couldn't search local docker for the required image\n%w", err)
		}
		if len(cs) > 0 {
			// The right image is already present
			return nil
		}
	}

	progress, err := docker.ImagePull(ctx, imageName, types.ImagePullOptions{})
	if err != nil {
		return fmt.Errorf("couldn't find tamago build image (%s)\n%w", imageName, err)
	}
	printProgress(progress)

	return nil
}

func printProgress(reader io.ReadCloser) {
	defer reader.Close()
	termFd, isTerm := term.GetFdInfo(os.Stderr)
	_ = jsonmessage.DisplayJSONMessagesStream(reader, os.Stderr, termFd, isTerm, nil)
}

func dirIsPresent(path string) bool {
	fileInfo, err := os.Stat(path)
	if err != nil {
		return false
	}
	return fileInfo.IsDir()
}

func exitWithUsage() {
	fmt.Printf("Usage: %s <target-device> [output-path] [path-to-main-package]\n", filepath.Base(os.Args[0]))
	os.Exit(1)
}

func exitWithError(msg string, args ...interface{}) {
	_, _ = fmt.Fprintf(os.Stderr, msg, args...)
	os.Exit(1)
}
