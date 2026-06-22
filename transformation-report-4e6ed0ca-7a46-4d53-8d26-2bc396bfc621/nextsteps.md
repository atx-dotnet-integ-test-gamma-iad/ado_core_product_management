# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48`, `netcoreapp3.1`, or other unintended frameworks.

### 2. Restore and Build Locally
Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues.

### 3. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and address them before proceeding.

### 4. Check for Removed or Changed APIs
Use the .NET Upgrade Assistant or the compatibility analyzer to identify any API usage that compiles but behaves differently on cross-platform .NET compared to .NET Framework:

```bash
dotnet tool install -g upgrade-assistant
upgrade-assistant analyze <solution>.sln
```

Pay particular attention to:
- `System.Windows.Forms` or `System.Web` references, which are not fully cross-platform.
- P/Invoke calls or Windows-specific registry/file path assumptions.
- `AppDomain`, `BinaryFormatter`, or `Remoting` usage, which is restricted or removed.

### 5. Review NuGet Package Compatibility
Open the `.csproj` files and verify that all referenced NuGet packages have versions compatible with your target framework. You can check compatibility on [nuget.org](https://www.nuget.org) or by inspecting the `lib` folders of the packages in the local cache.

Run the following to check for outdated packages:

```bash
dotnet list package --outdated
```

Update packages where necessary using:

```bash
dotnet add package <PackageName> --version <LatestCompatibleVersion>
```

### 6. Validate Configuration Files
If the project previously used `app.config` or `web.config`, confirm that settings have been migrated to `appsettings.json` or environment variables where appropriate, as `System.Configuration.ConfigurationManager` has limited support on cross-platform .NET.

### 7. Test on Target Platforms
If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues that would not appear at compile time.

```bash
dotnet run --configuration Release
```

## Deployment

### 1. Publish the Application
Use the `dotnet publish` command to produce deployment artifacts:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment that does not require the .NET runtime to be installed on the target machine:

```bash
dotnet publish --configuration Release --self-contained true --runtime linux-x64 --output ./publish
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, etc.) for your target environment.

### 2. Verify Published Output
Navigate to the `./publish` directory and confirm all expected binaries, configuration files, and assets are present before deploying to the target environment.