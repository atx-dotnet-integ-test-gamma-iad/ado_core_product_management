# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework is set to the intended cross-platform version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET version installed on your machine by running:

```bash
dotnet --version
```

## 2. Restore Dependencies

Run a NuGet restore to confirm all packages resolve correctly against the new target framework:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not fully support the target framework.

## 3. Build the Solution

Perform a full build to confirm no errors or warnings are introduced at compile time:

```bash
dotnet build --configuration Release
```

Address any warnings that could indicate compatibility issues, such as obsolete API usage or platform-specific code paths.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release
```

Review test output carefully. Any failures that did not exist in the legacy project should be investigated as potential behavioral differences introduced by the migration.

## 5. Verify Platform-Specific Code

Search the codebase for any APIs that were Windows-specific in the original project. Common areas to check include:

- `System.Windows.Forms` or `System.Drawing` usage
- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific P/Invoke calls
- `System.Security.Principal.WindowsIdentity`

If any of these are found, determine whether a cross-platform alternative exists or whether a platform guard (`RuntimeInformation.IsOSPlatform`) is appropriate.

## 6. Test on Target Platforms

Run and validate the application on each platform you intend to support, for example Linux or macOS, if cross-platform support is a goal:

```bash
dotnet run --configuration Release
```

Pay attention to file path separators, line endings, and environment variable differences between operating systems.

## 7. Publish the Application

Once validation is complete, publish the application for your target runtime. For a self-contained deployment targeting Linux x64 as an example:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

For a framework-dependent deployment:

```bash
dotnet publish --configuration Release
```

Review the contents of the `publish` output folder to confirm all required assets and dependencies are present before distributing or deploying the application.