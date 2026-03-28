# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

```xml
<TargetFramework>net8.0</TargetFramework>
```

If it is still referencing a Windows-only framework such as `net48`, update it accordingly.

## 2. Restore NuGet Packages

Run the following command from the solution root to ensure all dependencies are correctly restored:

```bash
dotnet restore
```

Review the output for any warnings about deprecated or incompatible packages.

## 3. Build the Solution

Perform a full build to confirm there are no errors:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly those related to nullable reference types or platform compatibility.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release
```

Review the test output and investigate any failures. Pay particular attention to tests that exercise database access, file I/O, or platform-specific APIs, as these are common sources of cross-platform issues.

## 5. Check for Platform-Specific API Usage

Use the .NET Compatibility Analyzer to identify any remaining Windows-specific API calls that may not behave correctly on Linux or macOS:

```bash
dotnet build /p:PlatformTarget=AnyCPU
```

Look for `CA1416` warnings in the build output, which indicate platform-specific API usage.

## 6. Validate ADO.NET Functionality

Since the project is named `AdoCore`, verify that all database connection strings, providers, and queries function correctly under the new framework. Confirm that the ADO.NET provider being used (e.g., `Microsoft.Data.SqlClient`, `Npgsql`) is the current cross-platform compatible version.

## 7. Test on Target Platforms

Run the application on each platform you intend to support (Windows, Linux, macOS) to catch any runtime behavior differences that do not surface at compile time:

```bash
dotnet run --configuration Release
```

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with the appropriate runtime identifier for your deployment target (e.g., `win-x64`, `osx-x64`). Review the contents of the publish output directory before deploying.