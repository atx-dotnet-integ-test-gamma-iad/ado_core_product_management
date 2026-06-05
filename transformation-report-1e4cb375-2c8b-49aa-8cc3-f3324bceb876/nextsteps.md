# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`).

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

## 2. Restore and Build Locally

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues even though they do not block compilation.

## 3. Review NuGet Package Versions

Open the `.csproj` file and check that all `<PackageReference>` entries reference versions compatible with your target framework. Run the following to identify outdated packages:

```bash
dotnet list package --outdated
```

Update packages where appropriate using:

```bash
dotnet add package <PackageName> --version <NewVersion>
```

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that runtime behavior is consistent with the original project:

```bash
dotnet test --configuration Release --verbosity normal
```

Review any failing tests carefully, as they may indicate behavioral differences introduced by the framework migration rather than pre-existing bugs.

## 5. Check for Platform-Specific API Usage

Even without build errors, some APIs may have been marked with `[SupportedOSPlatform]` attributes or may throw `PlatformNotSupportedException` at runtime on non-Windows systems. Search the codebase for common Windows-specific namespaces such as:

- `Microsoft.Win32`
- `System.Windows.Forms`
- `System.Drawing` (without the `System.Drawing.Common` package)

If any are found, evaluate whether a cross-platform alternative is needed.

## 6. Validate Configuration and App Settings

If the project uses configuration files (e.g., `App.config` or `Web.config`), confirm that settings have been migrated to `appsettings.json` or the appropriate .NET configuration model. The legacy XML-based configuration system has limited support in modern .NET.

## 7. Perform a Runtime Smoke Test

Run the application directly and exercise its primary functionality:

```bash
dotnet run --project AdoCore.csproj --configuration Release
```

Confirm that database connections, file I/O, and any other core operations behave as expected across the target platforms.

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime <rid> --self-contained false
```

Replace `<rid>` with the appropriate runtime identifier, for example:
- `win-x64` for Windows
- `linux-x64` for Linux
- `osx-x64` for macOS

Review the contents of the publish output folder before deploying to confirm all required assets are present.